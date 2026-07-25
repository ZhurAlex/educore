# Educore

A student testing app for the classroom: a teacher builds tests, assigns
them to a class, and prints/projects a QR code. Students scan it, pick their
name, confirm with a light DDMM passcode, and take the test — multiple
choice and short answer questions are graded automatically.

Full design rationale and decisions log: [docs/SPEC.md](docs/SPEC.md).

## Tech stack

- Ruby 3.3.0 / Rails 7.1
- PostgreSQL (via Docker Compose for local dev)
- Hotwire (Turbo + Stimulus), Sprockets — no JS framework, no bundler
- Devise (teacher auth — registration is closed, see SPEC Decision #11) + Pundit
- RSpec + FactoryBot + Faker
- I18n: `uk` (default), `ru`, `en` — UI chrome only, see SPEC's I18n section

## Setup

**Prerequisites:** [asdf](https://asdf-vm.com) (or any Ruby 3.3.0 install) and Docker.

```bash
asdf install                    # ruby 3.3.0, from .tool-versions
bundle install

cp .env.example .env            # Postgres credentials for docker-compose
docker compose up -d db

bin/rails db:prepare             # creates + migrates development and test DBs
bin/rails db:seed                # creates the teacher account + demo data (dev only)
```

`db:seed` prints the teacher login. Defaults (override via `SEED_TEACHER_EMAIL` /
`SEED_TEACHER_PASSWORD` / `SEED_TEACHER_NAME`):

- email: `teacher@example.com`
- password: `password123`

## Running

```bash
bin/rails server
```

Visit `http://localhost:3000` and sign in with the seeded teacher account
above. From there: create school classes and students, build a test,
assign it to a class, and open the QR code shown on the test's page — that
same link is what a student's phone lands on.

## Testing

```bash
bundle exec rspec
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
