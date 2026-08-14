# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
# require "active_job/railtie"
require 'active_record/railtie'
# require "active_storage/engine"
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require "action_mailbox/engine"
# require "action_text/engine"
require 'action_view/railtie'
# require "action_cable/engine"
# Not using Test::Unit/minitest — this project uses RSpec (see docs/SPEC.md
# Tech Stack).

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Educore
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # MVP locales — see docs/SPEC.md Decision #5. UI chrome only, never test
    # content (Question/Test bodies stay in whatever language they were
    # authored in — see docs/SPEC.md I18n section).
    config.i18n.available_locales = %i[uk ru en]
    config.i18n.default_locale = :uk
    # Anything not (yet) translated in uk/ru falls back to en rather than
    # rendering "translation missing" — most relevant for Devise's own copy
    # (sign in/password reset) and Rails' built-in ActiveRecord error
    # messages, neither of which are hand-translated here. `true` alone
    # would make the fallback chain default to *default_locale* (uk), which
    # doesn't help since uk has no built-in Rails strings either — the
    # explicit [:en] is what actually gets to a locale with those strings.
    config.i18n.fallbacks = [:en]
    config.active_job.queue_adapter = :sidekiq
  end
end
