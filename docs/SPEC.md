# Student Testing App — Technical Specification

## Context and Goal

Full-stack portfolio project built with Rails + Hotwire. Practical use case:
an application for testing students (e.g. in English) within a school class.

**Project goals:**
- Demonstrate solid command of Rails (models, controllers, migrations, validations)
- Demonstrate a modern approach to interactivity without a heavy SPA (Turbo/Stimulus)
- Lay groundwork for a future LLM integration (grading open-ended answers)
- Ship a genuinely usable tool for classroom use

**Author is a Ruby developer with 5 years of commercial experience, transitioning
toward LLM/agent engineering.** Part of the codebase is AI-generated, part is
written by hand — in particular, LLM-based answer grading is a separate,
self-implemented stage.

---

## User Flow

1. Teacher creates a school class, adds students (full name + date of birth),
   creates a test with questions, and assigns the test to one or more
   school classes (`TestAssignment`).
2. Teacher generates a QR code **per (test, school class) assignment** —
   scanning it opens that specific test with the right school class's
   student roster.
3. Student scans the QR code with their phone → lands on a page where they
   pick their name from the school class roster.
4. Student selects themselves from the list → enters a "passcode" — 4 digits
   in DDMM format (day and month of birth). This is **not full authentication**,
   just light protection against a classmate completing the test on someone
   else's behalf as a prank.
5. On a match — the test starts. Student answers questions (see question
   types below).
6. On completion — auto-gradable answers are scored immediately; if the test
   has `long_text` questions, those are graded asynchronously (see "LLM
   Grading" below) and the attempt briefly shows as still-being-reviewed
   before the final score is ready. The result becomes visible to the
   teacher in the admin panel either way.
7. Teacher reviews results, optionally overrides the auto-awarded points
   and/or feedback on individual questions — the final grade recomputes
   automatically. Student can also revisit their own results later — see
   Decision #14.

---

## Internationalization (I18n)

The app must support multiple languages from the start — both because the
target users (students, teachers) may not all be Russian/Ukrainian-speaking
in every deployment, and because building this in from day one avoids costly
retrofits later.

- Use Rails' built-in `I18n` module; store translations in
  `config/locales/*.yml` (one file per locale, namespaced by feature —
  e.g. `en.yml`, `uk.yml`, `ru.yml`).
- **No locale segment in the URL.** Multilingual support is for **UI chrome
  only** (buttons, instructions, error messages) — never for test content
  (see below), so there's no need to route `/en/...` vs `/uk/...`:
  - **Teacher-facing (admin panel):** a locale switcher persisted in
    `session[:locale]` — this is safe here because the teacher has a
    persistent, authenticated Devise session (unlike the student flow).
  - **Student-facing flow:** UI locale is read from the assigned `Test`'s
    `locale` attribute via a `before_action`, not chosen by the student and
    not inferred from `Accept-Language` (unreliable — a student's phone may
    be set to any language). Nothing for the student to pick.
- All user-facing strings — validation messages, flash messages, UI labels,
  button text — go through `I18n.t`, no hardcoded strings in views or
  controllers.
- **Question/test content itself is a separate concern from UI locale, and
  is never translated.** A test's questions are authored once, in whatever
  language the teacher writes them in (e.g. an English test stays in English
  regardless of UI locale) — no double/triple-authoring the same test in
  multiple languages. Only the UI chrome is multilingual.
- The QR code links straight to `/test_assignments/:id` (no locale prefix) —
  see Data Model's `TestAssignment` for why it targets the assignment, not
  the bare `Test`.
- **MVP locales: `uk`, `ru`, and `en` all ship at once** (not staggered) —
  `en` earns its keep for the portfolio/demo angle from day one.

---

## Data Model (draft)

```
Teacher
  - name, email, password_digest (Devise)
  has_many :tests

SchoolClass
  - name (e.g. "7-A") — no teacher_id; shared roster, not owned by one teacher
    (see "Ownership Model" below)
  has_many :students
  has_many :test_assignments
  has_many :tests, through: :test_assignments

Student
  - first_name, last_name, birth_date, school_class_id
  has_many :test_attempts

Test
  - title, teacher_id, locale (UI locale for the student-facing flow — see I18n section)
  has_many :test_assignments
  has_many :school_classes, through: :test_assignments
  has_many :questions
  has_many :test_attempts

TestAssignment
  - test_id, school_class_id
  - lets one test be assigned to multiple school classes (e.g. the same test
    reused for 7-A and 7-B); the per-test QR code is generated per
    (test, school class) pair so the student roster shown is the right one

Question
  - test_id, body, answer_type (enum: multiple_choice / short_text / long_text
    — see "Question Types and Grading Logic" below)
  - correct_answer (required for both short_text and long_text, different
    use: exact normalize+compare for short_text, a reference answer/rubric
    passed to Gemini for long_text — not used for multiple_choice, which
    uses Options instead. See "LLM Grading" below.)
  - points (decimal, minimum 0.5, step 0.5 — question weight)
  has_many :options (for multiple_choice)

Option
  - question_id, body, correct (boolean)

TestAttempt
  - student_id, test_id, status (in_progress / evaluating / completed).
    `evaluating` covers the gap between submission and `QuestionGraderJob`
    finishing long_text grading — auto-gradable responses already have a
    score at that point, but it isn't final until the job flips the status
    to `completed`. A test with no long_text questions never spends visible
    time in `evaluating` (the job still runs, but has nothing to grade).
  - score (decimal — sum of Response#points_awarded, computed automatically
    on completion; can be fractional, e.g. 8.5, since points are in 0.5
    increments; round up/ceiling, not standard rounding, wherever a whole
    number is needed)
  - grade (final grade — auto-computed as `score.ceil` whenever score
    changes, e.g. after the teacher overrides a response's points; not
    manually entered)
  - started_at, completed_at
  - one active (in_progress) attempt per (student, test) — enforced via a
    uniqueness validation/index; re-scanning the QR while an attempt is
    already in_progress resumes it rather than starting a new one
  has_many :responses

Response
  - test_attempt_id, question_id
  - answer_text (for short_text/long_text) or option_id (for multiple_choice)
  - grading_status (enum: auto_graded, teacher_overridden, pending,
    llm_graded, manual_check_required — see "LLM Grading" below for the
    long_text-specific values)
  - points_awarded
  - feedback (text, nullable) — Gemini's explanation for a long_text score,
    or a teacher's own note; same field either way, teacher edits overwrite
    it in place (mirrors how `points_awarded` + `teacher_overridden` already
    works, no separate "original vs edited" history is kept)
```

**Ownership model:** `SchoolClass` and `Student` are **shared** across all teachers
(no `teacher_id`) — a real teacher who isn't the homeroom teacher of a class
still needs to see and test its roster, so per-teacher-owned classes/rosters
don't match reality. `Test` is the one entity with `teacher_id`: each teacher
owns their own tests, and Pundit scopes on `Test`, not on `SchoolClass`. This
assumes a single-school, single-trusted-tenant deployment (every teacher in
the app can see every class/student) — multi-school isolation is out of
scope for MVP.

---

## Question Types and Grading Logic

All three answer types are auto-graded — `multiple_choice`/`short_text`
synchronously at submission, `long_text` asynchronously via an LLM.

| Type | Grading |
|---|---|
| `multiple_choice` | Automatic, exact match against the `correct` option |
| `short_text` | Automatic: normalize (lowercase, trim, strip punctuation) + compare to `correct_answer` |
| `long_text` | Asynchronous, via Gemini — see "LLM Grading" below |

Grading logic itself lives in `QuestionGrader` (`app/services/`), not on the
`Question` model — `Question#grade` is a one-line delegator. `QuestionGrader#grade`
returns a `GradeResult` (`Data.define(:points, :feedback, :error)`), the same
shape regardless of question type, so callers never branch on answer_type to
know what they got back.

Regardless of type, **the teacher can always manually override
`points_awarded` and `feedback` for any individual response** after
auto-grading — this is what `Response#grading_status: teacher_overridden` is
for.

---

## LLM Grading (`long_text`)

Submitting a test grades `multiple_choice`/`short_text` responses
synchronously, in the same request — but a `long_text` response requires an
HTTP round-trip to Gemini, which must not block that request or hold the DB
transaction open. So grading splits into two phases:

1. **Synchronous** (`TestAttemptsController#update`): auto-gradable
   responses are scored immediately; `long_text` responses are persisted
   with `answer_text` and `grading_status: pending`, no score yet. The
   attempt moves to `status: evaluating` (not `completed`), and
   `QuestionGraderJob.perform_later(test_attempt.id)` is enqueued
   unconditionally — even for attempts with no `long_text` questions, so
   there's only one code path to `completed` rather than a branch in the
   controller for "does this attempt need grading."
2. **Asynchronous** (`QuestionGraderJob`, Sidekiq): loads the attempt's
   `pending` responses, grades each via `QuestionGrader`, and once done
   moves the attempt to `status: completed` and recomputes `score`/`grade`.
   An attempt with nothing pending reaches `completed` immediately — the
   loop is a no-op.

**Provider integration** (`GeminiApiService`, `app/services/`): sends the
question body, the teacher's `correct_answer` (a reference answer/rubric —
required for `long_text` questions, same field short_text uses for exact
comparison, just interpreted differently) and the student's answer to Gemini
(`gemini-ai` gem), with `response_mime_type: 'application/json'` and a
`response_schema` requiring `score` (integer) and `feedback` (string, with a
schema-level description telling the model to answer in the question's
language, not the answer's — relevant for translation-exercise questions).
The 0–100 `score` Gemini returns is converted to the question's point scale
and rounded to the nearest 0.5 in Ruby (`QuestionGrader`), not asked of the
model directly.

**Failure handling**: `GeminiApiService` validates its own response (missing
text, invalid JSON, missing `score`, `score` not an Integer in `0..100`) and
wraps every failure — validation or a raised `Faraday::Error`/`JSON::ParserError`
— into one `GeminiApiService::GradingError`. `QuestionGrader` catches that
and returns a `GradeResult` with `error` set instead of raising further, so a
single bad Gemini call can't crash `QuestionGraderJob` for an attempt with
multiple long_text responses. `QuestionGraderJob` maps that into
`grading_status: manual_check_required` (flagged in red in the teacher's
per-response table) rather than leaving a response silently ungraded.

**Known gap**: Sidekiq needs Redis and a separate worker process
(`bundle exec sidekiq`) in every environment it runs in — this is set up for
local dev (`docker-compose.yml`) but **not yet for production** (Render).
Deployed as-is, `QuestionGraderJob.perform_later` would enqueue into a Redis
instance that doesn't exist there.

---

## Birth-Date "Passcode" — Clarification

This is not authentication in the classical sense (no Devise/JWT/token
sessions). Implementation: a simple check of 4 digits (DDMM derived from
`birth_date`) in the controller; on a match, the student's id is stored in
`session[:student_id]` for the duration of the test attempt. The goal is not
security — it's reducing the chance that someone completes the test on
behalf of another student as a joke.

**Session cleanup (superseded, see Decision #14):** results are now meant to
be re-visitable (student entry flow below), so `session[:student_id]` is no
longer cleared after viewing a completed attempt — it persists for the
browser session like any other Rails session cookie. The residual risk is a
classmate reloading the same page on a handed-over phone before the tab
closes and seeing that student's grade; consistent with this section's
opening line, that's an acceptable gap given the passcode was never real
authentication to begin with.

---

## Tech Stack

- **Rails 7.1.5** (pinned — already scaffolded in this repo's Gemfile)
- **Devise** — teacher authentication (registration closed; the one
  `Teacher` account is seeded via `db/seeds.rb`, not self-service sign-up —
  see Decisions)
- **Hotwire** (Turbo Streams/Frames + Stimulus) — for interactivity without an SPA
- **PostgreSQL** — runs locally via `docker-compose.yml` (same pattern as
  the TeacherBot project); `dotenv-rails` loads `.env` credentials into
  `config/database.yml`
- **RSpec** — model, controller, and request specs covering the full flow
- **Pundit** — teacher-side authorization (access limited to own tests;
  school classes/students are shared across all teachers — see "Ownership
  model" in Data Model)
- **rqrcode** (gem) — QR code generation
- **Rails I18n** — multi-language support (see section above)
- **Stimulus** — test timer (if a time limit is needed), dynamic question
  fields when building a test
- **Sidekiq + Redis** — background jobs: `QuestionGraderJob` (LLM grading,
  see "LLM Grading" above) and Devise's `deliver_later` emails. Redis runs
  locally via `docker-compose.yml`; **not yet configured in production**.
  `Sidekiq::Web` is mounted at `/sidekiq`, gated behind teacher auth
  (`authenticate :teacher do ... end` in `routes.rb`), not public.
- **gemini-ai** (gem) — thin wrapper around the Gemini API, used by
  `GeminiApiService` for long_text grading
- **rack-attack** — throttles `StudentPasscodesController#create` (10
  attempts/minute per student) — the public student-entry flow (see
  Decision #14) means the passcode-entry page is reachable without a saved
  link, so brute-forcing the 4-digit DDMM code is cheaper than it used to be
- **RuboCop** (`rubocop` + `rubocop-rails`, not the omakase preset) — the
  omakase gem disables most Layout/indentation cops by design; this project
  wants those checks, so it uses the plain gems instead

---

## MVP — Build Order

1. Models + migrations (Teacher, SchoolClass, Student, Test, TestAssignment,
   Question, Option, TestAttempt, Response)
2. Teacher auth (Devise)
3. Admin panel: CRUD for SchoolClass, Student, Test, Question, TestAssignment
   (Rails-way forms are fine for the first pass)
4. I18n setup: locale files; teacher-side session-based switcher; student-side
   `before_action` reading UI locale off the assigned `Test`
5. QR code generation per TestAssignment (test + school class)
6. Student flow: pick name → enter DDMM → take the test → results screen
7. Auto-grading for multiple_choice and short_text
8. Teacher results screen: list of attempts, per-answer detail with
   per-question point override (score/grade recompute automatically)
9. Seed data (`db/seeds.rb`) — see "Seed Data" section below

## Seed Data (`db/seeds.rb`)

`rails db:seed` should populate enough data to exercise the full user flow
end to end without any manual setup through the admin panel:

- **1 Teacher** — the single account created here (see Decision #11); no
  public sign-up.
- **1 SchoolClass** with **10 students** (fake full names + birth dates,
  varied enough to give distinct DDMM passcodes).
- **1 Test**, assigned to that class via `TestAssignment`, with at least one
  question of each MVP `answer_type` (`multiple_choice`, `short_text`) so
  both auto-grading paths are reachable immediately after seeding.

---

## Later (post-MVP)

- Configure Sidekiq/Redis in production (Render) — see "Known gap" in "LLM
  Grading" above; `long_text` grading itself is implemented, this is a
  deploy-environment gap, not a code gap
- Export results (CSV/PDF)
- Per-class/per-student progress statistics across multiple tests
- Time limit per test / per question

---

## Decisions (resolved)

1. **QR code: per test** (per `TestAssignment`, i.e. per test+classroom pair)
   — scanning opens that specific test directly with the correct roster.
2. **One active attempt per (student, test)** — re-scanning while an attempt
   is `in_progress` resumes it; a student may still have parallel attempts
   across *different* tests.
3. **No time limit in MVP** — deferred to "Later"; the Stimulus timer stays
   a self-contained feature to bolt on afterward.
4. **Rails version: 7.1.5**, pinned (already in this repo's Gemfile).
5. **MVP locales: `uk`, `ru`, `en`** — all three ship together, not staggered.
6. **Test ↔ SchoolClass is many-to-many** via `TestAssignment`, since QR is
   per-test-per-class and reusing a test across classes is expected.
7. **Teacher auth: Devise.**
8. **Student-facing UI locale** is an explicit attribute on `Test`, applied
   via `before_action` — **no locale segment in the URL.** Teacher-side
   locale switching uses `session[:locale]` instead (safe there, since the
   teacher has a persistent Devise session, unlike students). QR links go
   to `/test_assignments/:id` with no locale prefix — see I18n section.
9. **Model name: `SchoolClass`**, not `Classroom`. `Classroom` reads as a
   physical room, and `Class` was never an option — it collides with Ruby's
   built-in `Class` constant.
10. **`SchoolClass`/`Student` are shared, not teacher-owned.** A teacher who
    tests a class isn't necessarily its homeroom teacher, so per-teacher
    rosters don't match reality. Ownership/Pundit scope lives on `Test`
    (`teacher_id`) instead — see "Ownership model" in Data Model.
11. **Single-teacher scope.** This is a portfolio project for one teacher
    (the author), not a real multi-school SaaS — no roles beyond "teacher"
    (no vice-principal/admin), no per-school isolation. Devise registration
    is closed; the one `Teacher` account is created via `db/seeds.rb`, not a
    public sign-up form.
12. **`long_text` shipped** (revised — originally "dropped from MVP
    entirely, returns with manual/LLM review in Later"). Implemented via
    async LLM grading — see "LLM Grading" above — rather than a manual
    teacher-review-only step; the teacher can still override any response's
    points/feedback afterward regardless of how it was originally graded.
13. **Per-question points, auto-computed score and grade, teacher can only
    override at the question level.** `Question#points` is decimal, minimum
    0.5 step — the question's weight. `TestAttempt#score` is the
    auto-computed sum of `Response#points_awarded` the moment the attempt is
    submitted — can be fractional (e.g. 8.5). `TestAttempt#grade` is also
    automatic: `score.ceil`, recomputed whenever score changes — there is no
    manual "assign a grade" step. The teacher's only lever is overriding
    `points_awarded` on an individual response (`grading_status:
    teacher_overridden`), which cascades: recomputes `score`, which
    recomputes `grade`.
14. **Results are re-visitable, not shown once and discarded** (revised
    twice — originally "`session[:student_id]` is cleared on attempt
    completion", then a first public-browsing redesign, superseded by the
    version below). The one-time-view design made results practically
    unreachable again after closing the tab (no saved link, re-auth required
    a QR rescan) — and separately, async `long_text` grading (see "LLM
    Grading" above) means a student's score at submission time isn't
    necessarily final, so being able to check back later matters more than
    it did in MVP.

    Current flow, kept deliberately separate from the QR flow (QR remains
    the *only* way to start/resume a test — see `TestAssignmentsController`/
    `StudentPasscodesController`, unchanged):
    root (`/`) → `StudentEntryController#index` lists school classes →
    `#show` lists that class's students, by `Student#name_with_initial`
    ("Tony S.", not the full name) → `StudentHistoryController#new`/`#create`
    is a **separate DDMM login** from the QR flow's (different session
    concern: proving "which student am I" to browse history, not
    starting/resuming one specific attempt) → on success,
    `StudentHistoryController#index` lists every attempt that student has
    ever made, across all tests, linking into
    `TestAttemptsController#show` (which no longer clears the session on
    view).

    The `name_with_initial` roster is a deliberate privacy narrowing from
    the first version of this redesign, which listed full names of students
    who'd *completed a specific test* — publicly linking an identity to a
    test-completion status with no passcode check at all (flagged by
    CodeRabbit as Major). Now: the class roster is just "who's in this
    class" (no more sensitive than the pre-existing QR roster, which was
    already public), and the sensitive link — which tests a specific student
    has completed — is only visible after that student's own DDMM login.
    See "Session cleanup" in Birth-Date Passcode for the residual
    shared-device risk this still accepts (unchanged from before).
15. **Paper/printed test-takers are entirely outside the system** — no
    manual attempt-entry UI in MVP (or currently planned at all). The
    teacher handles printing and grading those separately; nothing about
    them touches the app's data model.
