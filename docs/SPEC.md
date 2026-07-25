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
6. On completion — the attempt is scored automatically, and the result
   becomes visible to the teacher in the admin panel.
7. Teacher reviews results, optionally overrides the auto-awarded points on
   individual questions — the final grade recomputes automatically.

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
  - test_id, body, answer_type (enum: multiple_choice / short_text — long_text
    deferred to "Later", see below)
  - correct_answer (reference answer for short_text normalization/compare)
  - points (decimal, minimum 0.5, step 0.5 — question weight)
  has_many :options (for multiple_choice)

Option
  - question_id, body, correct (boolean)

TestAttempt
  - student_id, test_id, status (in_progress / completed — with only
    auto-gradable question types in MVP, "completed" already means fully
    scored; a distinct "graded" state returns once long_text/manual review
    is reintroduced)
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
  - answer_text (for short_text) or option_id (for multiple_choice)
  - grading_status (enum: auto_graded, teacher_overridden — teacher can
    manually adjust points_awarded for any question after the fact;
    pending_review/llm_graded return with long_text in "Later")
  - points_awarded
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

**MVP ships `multiple_choice` and `short_text` only** — both fully
auto-gradable, so a `TestAttempt` is scored the moment it's submitted, no
manual review step needed. `long_text` is deferred entirely to "Later"
(it only makes sense once paired with manual or LLM grading — see below).

| Type | MVP Grading | Later |
|---|---|---|
| `multiple_choice` | Automatic, exact match against the `correct` option | — |
| `short_text` | Automatic: normalize (lowercase, trim, strip punctuation) + compare to `correct_answer` | — |
| `long_text` | *(not in MVP)* | New answer_type + `pending_review`/`llm_graded` statuses. Teacher grades manually in the admin panel, or a separate `AnswerGraderService` takes the question + grading criteria + student's answer, sends it to an LLM provider, and returns a score plus feedback. Reuse the provider-with-fallback pattern from the TeacherBot project. |

Regardless of type, **the teacher can always manually override
`points_awarded` for any individual response** after auto-grading — this is
what `Response#grading_status: teacher_overridden` is for, independent of
whether/when `long_text` gets added.

---

## Birth-Date "Passcode" — Clarification

This is not authentication in the classical sense (no Devise/JWT/token
sessions). Implementation: a simple check of 4 digits (DDMM derived from
`birth_date`) in the controller; on a match, the student's id is stored in
`session[:student_id]` for the duration of the test attempt. The goal is not
security — it's reducing the chance that someone completes the test on
behalf of another student as a joke.

**Session cleanup:** `session[:student_id]` (and any attempt-scoped session
key) must be cleared once the attempt is submitted/completed. The expected
case is each student using their own phone (with a printed/paper version for
students without a smartphone), but the session still shouldn't outlive the
attempt — otherwise a later scan on the same device could resume as the
previous student.

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

- `long_text` question type + its grading (manual review, then LLM grading
  via `AnswerGraderService`, provider with fallback) — add the `sidekiq` gem
  back at this point, so the LLM call doesn't block the request cycle
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
12. **`long_text` dropped from MVP entirely** (not just its grading) — MVP
    ships `multiple_choice` and `short_text` only, both auto-gradable.
    `long_text` + manual/LLM review return together in "Later".
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
14. **`session[:student_id]` is cleared on attempt completion** — see
    "Session cleanup" in Birth-Date Passcode. Most students are expected to
    use their own phone (paper fallback for those without one), but the
    session must not outlive the attempt regardless.
15. **Paper/printed test-takers are entirely outside the system** — no
    manual attempt-entry UI in MVP (or currently planned at all). The
    teacher handles printing and grading those separately; nothing about
    them touches the app's data model.
