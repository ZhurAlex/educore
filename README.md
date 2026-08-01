## Demo

Live at https://educore-gdt0.onrender.com/ — note this is free-tier hosting,
so the first request may take up to 50 seconds to wake the service up.

- email: `teacher@example.com`
- password: `password123`
  
# Educore

A student testing app for the classroom: a teacher builds tests, assigns
them to a class, and prints/projects a QR code. Students scan it, pick their
name, confirm with a light DDMM passcode, and take the test — multiple
choice and short answer questions are graded automatically.

Full design rationale and decisions log: [docs/SPEC.md](docs/SPEC.md).

## Tech stack

- Ruby 3.3.0 / Rails 7.1
- PostgreSQL + Redis (both via Docker Compose for local dev)
- Sidekiq — background jobs (currently: sending Devise emails via `deliver_later`,
  so a slow mail send doesn't block the request; see SPEC's "Later" section
  for the next thing it'll carry — LLM grading)
- Hotwire (Turbo + Stimulus), Sprockets — no JS framework, no bundler
- Devise (teacher auth — registration is closed, see SPEC Decision #11) + Pundit
- ActionMailer + `letter_opener_web` — emails are never really sent in dev;
  view them at `/letter_opener` instead
- RSpec + FactoryBot + Faker, coverage tracked with SimpleCov
- RuboCop (`rubocop-rails-omakase`) — lint/style, runs in CI as a separate
  job from the test suite
- I18n: `uk` (default), `ru`, `en` — UI chrome only, see SPEC's I18n section
- GitHub Actions CI — runs RSpec and RuboCop on every push/PR (see
  `.github/workflows/ci.yml`)

## Setup

**Prerequisites:** [asdf](https://asdf-vm.com) (or any Ruby 3.3.0 install) and Docker.

```bash
asdf install                    # ruby 3.3.0, from .tool-versions
bundle install

cp .env.example .env            # Postgres + Redis config for docker-compose
docker compose up -d             # Postgres + Redis

bin/rails db:prepare             # creates + migrates development and test DBs
bin/rails db:seed                # creates the teacher account + demo data (dev only)
```

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
                           # (e.g. password reset emails) queue up and never run
```

Visit `http://localhost:3000` and sign in with the seeded teacher account
above. From there: create school classes and students, build a test,
assign it to a class, and open the QR code shown on the test's page — that
same link is what a student's phone lands on.

Emails (e.g. "Forgot your password?") are never actually sent in
development — view them at `http://localhost:3000/letter_opener` instead.

## Testing

```bash
bundle exec rspec        # runs the suite, generates a SimpleCov report at coverage/index.html
bundle exec rubocop      # lint/style — same check CI runs
```

## Project structure notes

- `docs/SPEC.md` is the source of truth for *why* things are built the way
  they are (data model, ownership rules, grading logic, decisions log) —
  read it before making structural changes.
- Registration is intentionally closed (single-teacher portfolio project,
  see SPEC Decision #11) — there is no sign-up flow.
- `long_text` questions and LLM-assisted grading are deferred (SPEC
  Decision #12) — MVP only supports `multiple_choice` and `short_text`,
  both auto-graded.
