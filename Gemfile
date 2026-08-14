# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.3.0'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.1.5'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Hotwire — see docs/SPEC.md Tech Stack / project goals
gem 'importmap-rails'
gem 'stimulus-rails'
gem 'turbo-rails'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Teacher authentication
gem 'devise'
gem 'devise-i18n'

# Teacher-side authorization (own tests only — see docs/SPEC.md Ownership model)
gem 'pundit'

# QR code generation for TestAssignment links
gem 'rqrcode'

# Throttle passcode brute-forcing — see docs/SPEC.md Birth-Date Passcode
gem 'rack-attack'

gem 'connection_pool', '~> 2.5'
gem 'sidekiq', '~> 7.3'

gem 'jsbundling-rails', '>= 1.3.1'

gem 'gemini-ai', '>= 4.3'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows]

  # binding.pry — step commands (next/step/continue) need pry-byebug on top
  gem 'pry-byebug'
  gem 'pry-rails'

  # Load .env into ENV for local dev/test (Postgres runs in docker-compose)
  gem 'dotenv-rails'

  # Lint/style checks (see docs/SPEC.md issue #17) — RuboCop's own defaults
  # (indentation, quote style, alignment, etc.), plus Rails-specific cops.
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false

  # Testing (see docs/SPEC.md Tech Stack)
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'letter_opener_web'
  gem 'rspec-rails'
  gem 'simplecov', require: false
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end
