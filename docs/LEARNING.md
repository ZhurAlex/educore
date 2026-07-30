# LEARNING — Things to Go Back and Understand Deeper

Not urgent, not blocking a feature — this is a running list of
libraries/tools I set up and can *operate* (configure, wire up, debug the
obvious failure modes), but haven't gone deep enough on to say I really
*know* them. Revisit one at a time, whenever there's no feature pressure —
not as a gate on shipping.

For each: what I can already do vs. what the actual gap is.

---

## Sidekiq

**Can do:** configure client/server Redis connections separately, pin
compatible gem versions (hit and fixed the `connection_pool` conflict
twice), know why `deliver_later`/`perform_later` + `queue_adapter` are both
needed, know the worker is a separate process from the Rails server.

**Gap:** how a job actually gets serialized into Redis (what the stored
payload looks like), the retry/backoff algorithm on failure, how
concurrency/thread-pool sizing works in practice, the middleware chain,
what Sidekiq Pro/Enterprise adds over OSS.

---

## Redis

**Can do:** run it via Docker Compose, point Sidekiq at it, understand
it's a shared in-memory store — here, used purely as Sidekiq's queue.

**Gap:** the persistence model (RDB snapshots vs. AOF, and the tradeoffs),
which actual Redis data structures Sidekiq uses for queues (lists? sorted
sets, for scheduled/retry jobs?), eviction policies, why single-threaded
Redis is still fast (event loop model).

---

## Devise

**Can do:** pick modules per model (`:database_authenticatable`,
`:recoverable`, `:rememberable`, `:validatable`), know registration is
closed just by omitting `:registerable`, override `send_devise_notification`
to route mail through `deliver_later`.

**Gap:** how each module actually *implements* its behavior under the
hood — how `:recoverable` generates and expires the reset token, how
`:rememberable`'s cookie survives tampering, how `:database_authenticatable`
compares passwords (bcrypt mechanics, not just "it's hashed").

---

## Pundit

**Can do:** write `authorize`/`policy_scope` calls, write a policy class
with per-action methods + a `Scope`, know that `authorize` infers the
policy method from the current action's name (and where that bit me —
`AttemptsController#index`).

**Gap:** writing a policy completely from scratch without the generator,
the `verify_authorized`/`verify_policy_scoped` safety callbacks (not used
in this app at all), how `Pundit::NotAuthorizedError` actually gets raised
internally, testing policies in isolation instead of only indirectly via
request specs.

---

## connection_pool

**Can do:** explain what it's for in general terms, know why Sidekiq
needs it and why the version matters here.

**Gap:** never used the API directly (`ConnectionPool.new` / `#with`) —
only ever encountered it as someone else's dependency, never had to reach
for it myself.
