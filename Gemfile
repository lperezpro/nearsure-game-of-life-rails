# frozen_string_literal: true

source "https://rubygems.org"

gem "bootsnap", require: false
gem "good_migrations"
gem "ostruct"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "rails", "~> 8.0.2"
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"
gem "thruster", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "brakeman", require: false
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "dotenv", ">= 3.0"
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "rswag"
end

group :development do
  gem "annotaterb"
  gem "bundler-audit", require: false
  gem "rubocop", require: false
  gem "rubocop-factory_bot", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "tomo", "~> 1.18", require: false
end

group :test do
  gem "shoulda-matchers"
end
