# Gemfile
#
# frozen_string_literal: true
# warn_indent:           true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.3'

# =============================================================================
# Rails and related gems
# =============================================================================

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0'

# Use Puma as the app server
gem 'puma'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# =============================================================================
# Asset-related gems
# =============================================================================

# Use SCSS for stylesheets.
gem 'sassc-rails'

# Use Uglifier as compressor for JavaScript assets.
gem 'uglifier'

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
# gem 'coffee-rails', '~> 4.2'

# Turbolinks makes navigating your web application faster.
# Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# =============================================================================
# Application gems
# =============================================================================

# == AuthN/AuthZ
gem 'devise'
gem 'oauth2', '~> 1.4'
gem 'omniauth-oauth2', '~> 1.6'
gem 'cancancan'
gem 'rolify'

# == Serialization
gem 'faraday'
gem 'multi_json'
gem 'nokogiri'
gem 'oj'
gem 'representable', '~> 3.0'
gem 'virtus', '~> 1.0'

# == Metrics
gem 'prometheus-client'

# == Other
gem 'iso-639'
gem 'jquery-rails'
gem 'sanitize'

# =============================================================================
# Production
# =============================================================================

group :production, :development do

  # Use MySQL as the database for Active Record.
  gem 'mysql2'

end

# =============================================================================
# Non-production
# =============================================================================

group :development, :test do

  # Call 'byebug' anywhere in the code to stop execution and get a debugger
  # console.
  gem 'byebug', platforms: %i[mri mingw x64_mingw]

end

group :development do

  # Access an interactive console on exception pages or by calling 'console'
  # anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'

  # Spring speeds up development by keeping your application running in the
  # background. Read more: https://github.com/rails/spring
  # gem 'spring'
  # gem 'spring-watcher-listen', '~> 2.0.0'

end

# =============================================================================
# Test only
# =============================================================================

group :test do

  # NOTE: currently using SQLite for tests.
  gem 'sqlite3'

  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'

  # Automatic installation and updates for all supported webdrivers.
  gem 'webdrivers', '~> 4.0'

  # For test coverage.
  gem 'simplecov'

end
