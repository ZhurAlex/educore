# Educore

A student testing app for the classroom: a teacher builds tests, assigns
them to a class, and prints/projects a QR code. Students scan it, pick their
name, confirm with a light DDMM passcode, and take the test — multiple
choice and short answer questions are graded automatically, and open-ended
answers are graded by an LLM (Gemini) in the background.

Full design rationale and decisions log: [docs/SPEC.md](docs/SPEC.md).

## Demo

Live at https://educore-gdt0.onrender.com/ — note this is free-tier hosting,
so the first request may take up to 50 seconds to wake the service up.

- email: `teacher@example.com`
- password: `password123`

Registration is closed (single-teacher portfolio project) — use the demo
account above to sign in.

## Tech stack

- Ruby 3.3.0 / Rails 7.1
- PostgreSQL + Redis (both via Docker Compose for local dev)
- Sidekiq — background jobs: `QuestionGraderJob` (long_text answers graded
  by Gemini, see below — a slow/failing LLM call must not block the
  request or hold a DB transaction open) and Devise's `deliver_later`
  emails. **Not yet configured in production** — see SPEC's "LLM Grading"
  section for that gap. `Sidekiq::Web` is mounted at `/sidekiq`, behind
  teacher auth.
- Gemini (`gemini-ai` gem, via `GeminiApiService`) — grades open-ended
  (`long_text`) answers: 0–100 score converted to the question's point
  scale, plus written feedback shown to both student and teacher. See SPEC's
  "LLM Grading" section for the full pipeline (async job, error handling,
  `manual_check_required` fallback).
- rack-attack — throttles the passcode-entry endpoint (public since the
  student-entry redesign, see SPEC Decision #14)
- Hotwire (Turbo + Stimulus) for the teacher-facing admin UI, no bundler
  needed there (importmap-rails)
- React (esbuild via `jsbundling-rails`) for the student test-taking page —
  a separate, independent JS pipeline living alongside importmap, not
  replacing it (see `app/javascript/react/`)
- Devise (teacher auth — registration is closed, see SPEC Decision #11) + Pundit
- ActionMailer + `letter_opener_web` — emails are never really sent in dev;
  view them at `/letter_opener` instead
- RSpec + FactoryBot + Faker, coverage tracked with SimpleCov
- RuboCop (`rubocop` + `rubocop-rails`) — lint/style, runs in CI as a
  separate job from the test suite
- I18n: `uk` (default), `ru`, `en` — UI chrome only, see SPEC's I18n section
- GitHub Actions CI — runs RSpec and RuboCop on every push/PR (see
  `.github/workflows/ci.yml`)

## Setup

**Prerequisites:** [asdf](https://asdf-vm.com) (or any Ruby 3.3.0 install),
Docker, and Node.js (any recent LTS — used only to build the React bundle
below, not for anything else).

```bash
asdf install                    # ruby 3.3.0, from .tool-versions
bundle install

npm ci                          # installs esbuild + react
npm run build                   # compiles app/javascript/react into app/assets/builds

cp .env.example .env            # Postgres + Redis config for docker-compose
docker compose up -d             # Postgres + Redis

bin/rails db:prepare             # creates + migrates development and test DBs
bin/rails db:seed                # creates the teacher account + demo data (dev only)
```

Add a Gemini API key to `.env` (from [Google AI Studio](https://aistudio.google.com/apikey))
to grade `long_text` questions:

```
GEMINI_API_KEY=your-key-here
```

Without it, `long_text` submissions still go through the full async flow —
they just fail at the Gemini request and end up flagged
`manual_check_required` for the teacher to grade by hand (see SPEC's "LLM
Grading" section).

`db:seed` prints the teacher login. Defaults (override via `SEED_TEACHER_EMAIL` /
`SEED_TEACHER_PASSWORD` / `SEED_TEACHER_NAME`):

- email: `teacher@example.com`
- password: `password123`

## Running

Three things need to be running at once — Postgres/Redis (Docker), the Rails
server, and the Sidekiq worker (separate process, not part of `rails server`):

```bash
docker compose up -d       # if not already running
bin/rails server           # terminal 1
bundle exec sidekiq        # terminal 2 — without this, background jobs
                           # (password reset emails, long_text grading)
                           # queue up and never run
```

Visit `http://localhost:3000` and sign in with the seeded teacher account
above. From there: create school classes and students, build a test,
assign it to a class, and open the QR code shown on the test's page — that
same link is what a student's phone lands on.

Emails (e.g. "Forgot your password?") are never actually sent in
development — view them at `http://localhost:3000/letter_opener` instead.

**Working on the React test-taking page** (`app/javascript/react/`): the
compiled bundle is not rebuilt automatically on save. Run this in its own
terminal while editing:

```bash
npm run build:watch
```

## Testing

```bash
npm run build             # request specs render this page, so the JS bundle
                           # must exist first — see app/javascript/react/
bundle exec rspec         # runs the suite, generates a SimpleCov report at coverage/index.html
bundle exec rubocop       # lint/style — same check CI runs
```

## Project structure notes

- `docs/SPEC.md` is the source of truth for *why* things are built the way
  they are (data model, ownership rules, grading logic, decisions log) —
  read it before making structural changes.
- Registration is intentionally closed (single-teacher portfolio project,
  see SPEC Decision #11) — there is no sign-up flow.
- `long_text` grading logic lives in `app/services/` (`QuestionGrader`,
  `GeminiApiService`), not on the `Question`/`Response` models — see SPEC's
  "LLM Grading" section before touching it.
