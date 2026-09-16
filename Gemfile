# frozen_string_literal: true

ruby file: ".ruby-version"
source "https://rubygems.org"

gem "hanami", "~> 3.0"
gem "hanami-action", "~> 3.0"
gem "hanami-assets", "~> 3.0"
gem "hanami-db", "~> 3.0"
gem "hanami-router", "~> 3.0"
gem "hanami-view", "~> 3.0"

gem "dry-types", "~> 1.7"
gem "dry-validation"
gem "dry-operation"
gem "puma"
gem "rack", "~> 2.2"
gem "rake"
gem "sqlite3"

# Tilt 2.9 registers its own template for the "html.erb" extension, which takes priority over
# hanami-view's ERB engine and breaks block-capture helpers like `form_for`. Fixed upstream in
# https://github.com/hanami/view/pull/284, not yet released. Remove this pin once hanami-view
# ships a release containing that fix.
gem "tilt", "< 2.4"

group :development do
  gem "hanami-webconsole", "~> 3.0"
end

group :development, :test do
  gem "dotenv"
end

group :cli, :development do
  gem "hanami-reloader", "~> 3.0"
end

group :cli, :development, :test do
  gem "hanami-rspec", "~> 3.0"
end

group :test do
  # Database
  gem "database_cleaner-sequel"

  # Web integration
  gem "capybara"
  gem "rack-test"
end
