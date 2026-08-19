# API Contract — `educore` → `educore-analytics`

Read-only JSON API, built specifically for `../educore-analytics` (not a
general-purpose public API). Full data model/architecture: `docs/SPEC.md`.

## Authentication

Shared-secret bearer token, not a real auth system (single trusted
consumer, not multi-tenant) — same spirit as the rest of this app's
lightweight auth choices, see SPEC's "Birth-Date Passcode" section.

```
Authorization: Bearer <token>
```

The token is the `ANALYTICS_API_KEY` environment variable — **the same
value must be set on both `educore` and `educore-analytics`**. Missing or
wrong token → `401 Unauthorized`, empty body.

Constant-time comparison (`ActiveSupport::SecurityUtils.secure_compare`),
implemented in `Api::ApplicationController#authenticate_api_token!`.

## `GET /api/test_attempts`

Returns `TestAttempt`s — **all statuses** (`in_progress`/`evaluating`/`completed`),
not just finished ones. Rationale: what the student actually wrote
(`answer_text`/`option_id`) is already final by the time an attempt reaches
`evaluating`, even though the `long_text` score/feedback may not be yet — see
SPEC's "LLM Grading" section. `in_progress` attempts have no `Response`s yet
(nothing is persisted until submission), so they come back with an empty
`responses` array rather than partial data.

### Query parameters (all optional, combine with AND)

| Param | Filters by |
|---|---|
| `test_id` | `TestAttempt#test_id` |
| `student_id` | `TestAttempt#student_id` |
| `school_class_id` | the attempt's student's `school_class_id` |
| `subject` | the attempt's test's `subject` (`math`/`english`) |

No params → every `TestAttempt` in the system. Implemented as composable
scopes on `TestAttempt` (`for_test`/`for_student`/`for_school_class`/`for_subject`
in `app/models/test_attempt.rb`) — safe to combine any subset.

### Response shape

`200 OK`, a JSON array of:

```jsonc
{
  "id": 13,
  "status": "completed",           // in_progress | evaluating | completed
  "score": 3.0,                    // sum of points_awarded; null if nothing graded yet
  "student": { "id": 18, "name": "Джин Грей" },
  "test": { "id": 6, "title": "New test 2", "subject": "math" },
  "responses": [
    {
      "question": "Capital of France?",
      "answer": "Paris",           // answer_text (short_text/long_text) or the chosen Option#body (multiple_choice)
      "points_awarded": 2.0,       // 0 for ungraded/wrong; null semantics not used, always a number
      "max_points": 2.0,           // the question's own point value — needed to compute a ratio, points_awarded alone isn't comparable across questions
      "feedback": null,            // only ever populated for long_text (Gemini's explanation, or a teacher's own note); always null for multiple_choice/short_text
      "grading_status": "auto_graded" // auto_graded | teacher_overridden | pending | llm_graded | manual_check_required
    }
  ]
}
```

**Numeric fields are cast to native JSON numbers, not strings.** Rails'
`decimal` columns (`score`, `points_awarded`, `points`) serialize to JSON as
strings by default (`"2.0"`, not `2.0`) — `Api::TestAttemptSerializer`
explicitly calls `.to_f` on all of them so the contract is a real number, not
something the consumer has to remember to parse.

**Deliberately excluded:** `Student#birth_date` (that's the DDMM passcode —
never exposed anywhere, including here) and `Question#correct_answer` (the
reference answer/rubric — not needed for gap analysis, and multiple_choice's
"correct" comes through as which `Option#body` was picked vs. `answer_text`
for the others, not a separate correct-answer field).

### Implementation

- `Api::ApplicationController` (`app/controllers/api/`) — token auth, base
  class for every API controller. `ActionController::Base`, not
  `ApplicationController` — this namespace has nothing in common with the
  rest of the app (no session, no Devise, no locale switching).
- `Api::TestAttemptsController#index` — applies the scopes, delegates
  shaping to the serializer.
- `Api::TestAttemptSerializer` (`app/serializers/api/`) — plain PORO, no
  serializer gem. One instance per record; `index` builds the array via
  `.map`, not some `render json:, each_serializer:` mechanism (that's an
  `active_model_serializers` feature — this app doesn't have that gem).

### Known gaps

- No pagination. Fine at current data volume (single teacher, low
  question/response counts); revisit if `educore-analytics` starts pulling
  enough data for this to matter.
- No versioning (`/api/`, not `/api/v1/`) — deliberate for now, single
  consumer under the same person's control; see `educore/CLAUDE.md`'s
  companion-project note for the reasoning.
