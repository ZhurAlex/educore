source "https://rubygems.org"

ruby "3.3.0"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.5"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Hotwire — see docs/SPEC.md Tech Stack / project goals
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Teacher authentication
gem "devise"

# Teacher-side authorization (own tests only — see docs/SPEC.md Ownership model)
gem "pundit"

# QR code generation for TestAssignment links
gem "rqrcode"

gem "sidekiq", "~> 7.3"
gem "connection_pool", "~> 2.5"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]

  # binding.pry — step commands (next/step/continue) need pry-byebug on top
  gem "pry-rails"
  gem "pry-byebug"

  # Load .env into ENV for local dev/test (Postgres runs in docker-compose)
  gem "dotenv-rails"

  # Testing (see docs/SPEC.md Tech Stack)
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "letter_opener_web"
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

