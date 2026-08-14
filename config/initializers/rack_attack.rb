# frozen_string_literal: true

module Rack
  class Attack
    # Rack::Attack defaults to Rails.cache, but this app sets that to
    # :null_store in test (see config/environments/test.rb) — nothing would
    # ever get counted there. Use a dedicated in-process store instead, kept
    # independent of whatever the app's own fragment-cache config is.
    cache.store = ActiveSupport::Cache::MemoryStore.new

    # DDMM passcode is only 4 digits (~366 valid dates) and, since the public
    # student entry flow (docs/SPEC.md Decision #14) no longer requires a
    # private link to reach it, it's brute-forceable by anyone browsing to a
    # student's passcode page. Throttle attempts per student rather than per
    # IP, since a whole class could plausibly share a school network/IP.
    throttle('student_passcodes/create', limit: 10, period: 1.minute) do |req|
      # :student_id is a route path segment, not a query/form param — Rack::
      # Attack runs ahead of Rails routing, so it has to be pulled out of the
      # raw path here instead of via req.params.
      match = req.path.match(%r{/students/(\d+)/passcode\z})
      match[1] if req.post? && match
    end
  end
end
