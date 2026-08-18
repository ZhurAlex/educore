# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Rails 7.1 + Hotwire student-testing app for a single teacher's classroom (portfolio project). Full technical spec, data model, and decisions log: `docs/SPEC.md`. Setup/running instructions: `README.md`.

**Companion project:** `../educore-analytics` (Python) — will read **every** `Response`, not just `long_text` ones, to surface learning-gap patterns for teachers: which wrong option a student keeps picking on `multiple_choice`, common wrong `short_text` answers, and `long_text` mistakes/feedback all carry signal. Not yet built; the schema it depends on (`Response#answer_text`/`option_id`/`points_awarded`/`feedback`/`grading_status`, `Question#answer_type`/`correct_answer`) is documented below and in `docs/SPEC.md`'s "LLM Grading" section (that section is `long_text`-specific — the rest of the `Response`/`Question` shape applies to all three answer types).

**Data access is decided as API, not direct DB access — but the API doesn't exist in this app yet.** That's a real prerequisite here before `educore-analytics` can pull anything real: endpoints, auth between the two services, and a JSON contract still need designing. Once that contract is settled, document it in a small, dedicated file (e.g. `docs/API_CONTRACT.md`, not folded into the much larger `docs/SPEC.md`) so `educore-analytics/CLAUDE.md` can `@`-import just that. **If you're working on that API/contract, also read `../educore-analytics/CLAUDE.md`** — it documents what the consumer actually expects to read; not auto-imported here since most work in this repo has nothing to do with the analytics side.

## Commands

```bash
docker compose up -d               # Postgres + Redis — required before anything below
bin/rails db:prepare                # create + migrate dev/test DBs
bin/rails db:seed                   # demo teacher + data (dev only)

npm run build                       # compiles the React bundle — request specs that
                                     # render the student test-taking page need this
                                     # to exist first
npm run build:watch                 # rebuild on save; run in its own terminal while
                                     # editing app/javascript/react/

bin/rails server                    # web app, localhost:3000
bundle exec sidekiq                 # separate process — required for long_text grading
                                     # and Devise emails to actually run, not just queue

bundle exec rspec                           # full suite
bundle exec rspec spec/path/to_spec.rb      # single file
bundle exec rspec spec/path/to_spec.rb:42   # single example at that line
bundle exec rubocop                         # lint — same check CI runs
bundle exec rubocop -a <file>               # autocorrect one file
```

## Architecture

### Three user-facing surfaces, three different auth models

- **Teacher admin** (`SchoolClassesController`, `TestsController`, `QuestionsController`,
  `AttemptsController`, etc.) — Devise session auth (`authenticate_teacher!`, the
  default on `ApplicationController`), Hotwire/Turbo, no JS bundler beyond importmap.
  Pundit scopes `Test` to its owning teacher; `SchoolClass`/`Student` are shared across
  all teachers, not owned — see SPEC's "Ownership model".
- **Student test-taking** (`TestAttemptsController#show`/`#update`) — no Devise; access
  gated by `session[:student_id]` set during passcode verification. The in-progress
  question form is a **React** app (`app/javascript/react/`, compiled via
  jsbundling-rails/esbuild — a separate pipeline from the importmap one used for the
  admin UI). Submission goes through `#update` as a JSON fetch, not a Turbo form.
- **Public student-entry / results browsing** (`StudentEntryController`,
  `StudentHistoryController`) — fully public, no session required just to browse class
  and student names. Deliberately kept separate from the QR flow
  (`TestAssignmentsController`/`StudentPasscodesController`, unchanged — still the only
  way to start/resume a test). See SPEC Decision #14 for why these are split and what
  each is scoped to.

Controllers default to requiring teacher auth (`before_action :authenticate_teacher!`
on `ApplicationController`) — every public/student-facing controller explicitly
`skip_before_action :authenticate_teacher!`.

### Grading: synchronous vs. async, and where the logic actually lives

`Question#grade` is a one-line delegator to `QuestionGrader` (`app/services/`) —
grading logic doesn't live on the model. `QuestionGrader#grade` always returns a
`GradeResult` (`Data.define(:points, :feedback, :error)`), the same shape for every
answer type, so callers never branch on `answer_type` to know what they got back.

- `multiple_choice`/`short_text` grade synchronously, inside `TestAttemptsController#update`.
- `long_text` grades asynchronously: the controller marks the response `pending` and
  moves the `TestAttempt` to `status: evaluating` (not `completed`), then enqueues
  `QuestionGraderJob` (Sidekiq) unconditionally — even for attempts with zero
  `long_text` questions, so there's one code path to `completed` rather than a branch
  for "does this attempt need grading." `QuestionGraderJob` grades every `pending`
  response and only then flips the attempt to `completed`.
- `GeminiApiService` (`app/services/`) is the only thing that talks to Gemini. It wraps
  every failure mode — network errors, malformed JSON, a `score` that's
  missing/non-integer/out of `0..100` — into one `GeminiApiService::GradingError`.
  `QuestionGrader` catches that and returns a `GradeResult` with `error` set instead of
  raising, so one bad Gemini call can't crash grading for an attempt with multiple
  `long_text` responses; `QuestionGraderJob` maps a caught error to
  `grading_status: manual_check_required` instead of leaving a response silently
  ungraded.
- `Question#correct_answer` is required for both `short_text` (exact normalize +
  compare) and `long_text` (passed to Gemini as a reference answer/rubric — required so
  the model isn't grading blind).

Full detail, including the production Sidekiq deployment trade-off (runs inside the
one Render web service, not a dedicated worker): `docs/SPEC.md` → "LLM Grading".

### I18n: two independent locale mechanisms — don't mix them up

- Teacher-facing: `session[:locale]`, switched via `LocalesController`.
- Student-facing (both the QR flow and result pages): locale comes from `Test#locale`,
  applied via a per-controller `around_action :switch_locale_to_test` — **not**
  session-based, since students don't have a persistent session and shouldn't see a
  locale switcher. `StudentEntryController`/`StudentHistoryController` (browsing before
  any specific test is chosen) fall back to `ApplicationController`'s default
  (`session[:locale] || I18n.default_locale`) since there's no single test to derive
  from yet.
- Question/test content itself is never translated — authored once in whatever
  language the teacher wrote it in.

### Testing conventions worth knowing before writing specs

- External services are stubbed at the boundary, never hit for real: `GeminiApiService`
  specs replace `Gemini.new` (`allow(Gemini).to receive(:new)`) *before*
  `GeminiApiService.new` is constructed — its `initialize` calls the real `Gemini.new`,
  which resolves Google Auth credentials and will blow up in test runs if
  `GEMINI_API_KEY` isn't valid otherwise.
- `config.action_dispatch.show_exceptions = :rescuable` in the test environment —
  `ActiveRecord::RecordNotFound` etc. become normal HTTP responses in request specs
  (assert via `have_http_status(:not_found)`), not raised exceptions.
- `student_entry`/`student_history`/`test_attempts` request specs sign in by actually
  posting to the passcode endpoint (e.g. `post student_passcode_path(...)`) rather than
  manipulating `session` directly — mirrors how a student actually reaches these pages.
