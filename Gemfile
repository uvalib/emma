# Gemfile
#
# frozen_string_literal: true
# warn_indent:           true

source 'https://rubygems.org'
git_source(:github) { "https://github.com/#{_1}.git" }

ruby '3.4.1'

# =============================================================================
# Rails and related gems
# =============================================================================

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 8'

# Use Postgres as the database for Active Record.
gem 'pg'

# Use Puma as the app server
gem 'puma'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# =============================================================================
# Asset-related gems
# =============================================================================

# Handling of JavaScript by the "esbuild" module via "yarn build".
gem 'jsbundling-rails'

# Handling of stylesheets by the "sass" module via "yarn build:css".
gem 'cssbundling-rails'

# Still using Sprockets for file assets and ERB translation.
gem 'sprockets-rails'

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
# gem 'coffee-rails', '~> 4.2'

# Turbolinks makes navigating your web application faster.
# Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

# =============================================================================
# Application gems
# =============================================================================

# == AuthN/AuthZ
gem 'cancancan'
gem 'devise'
gem 'omniauth', '~> 2.1'
gem 'omniauth-rails_csrf_protection'
gem 'recaptcha'

# == Serialization
gem 'faraday'
gem 'faraday-retry'
gem 'multi_json'
gem 'nokogiri'
gem 'oj'
gem 'representable', '~> 3.0', '< 3.1'
gem 'virtus', '~> 1.0'

# == Logging
gem 'request_store'
gem 'silencer'

# == Metrics
gem 'prometheus-client'

# == Upload/download
gem 'archive-zip'
gem 'aws-sdk-s3'
gem 'pdf-reader'
gem 'shrine', '~> 3.0'

# == API support
gem 'rack-cors'

# == Job scheduler
gem 'good_job'

# == Session store
gem 'activerecord-session_store'

# == Other
gem 'csv'
gem 'draper'
gem 'iso-639'
gem 'sanitize'
gem 'workflow', '< 3.0'

# == Temporary

# NOTE: Apparently version 0.1.1 was removed.
gem 'declarative-option', '~> 0.1.0' # TODO: remove with representable >= 3.1

# =============================================================================
# Production
# =============================================================================

group :production, :development do

  # ???

end

# =============================================================================
# Non-production
# =============================================================================

group :development, :test do

  # Call 'byebug' anywhere in the code to stop execution and get a debugger
  # console.
  gem 'byebug', platforms: %i[mri mingw x64_mingw], require: false

end

group :development do

  # Added here so that RubyMine will see RBS in gems on the desktop.
  gem 'rbs', require: false

  # Access an interactive console on exception pages or by calling 'console'
  # anywhere in the code.
  gem 'web-console', require: false
  gem 'listen', require: false

  # Spring speeds up development by keeping your application running in the
  # background. Read more: https://github.com/rails/spring
  # gem 'spring', require: false
  # gem 'spring-watcher-listen', '~> 2.0.0', require: false

  # For dynamic reloading of changed assets
  gem 'foreman', require: false

end

# =============================================================================
# Test only
# =============================================================================

group :test do

  # Adds support for Capybara system testing and selenium driver
  gem 'capybara'
  gem 'capybara-lockstep'
  gem 'selenium-webdriver'

  # For Select2 menus.
  gem 'capybara-select-2'

  # For test coverage.
  gem 'simplecov'

  # Needed by minitest but not an implicit part of Ruby 3.4.
  gem 'mutex_m'

end
