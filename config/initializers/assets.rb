# config/initializers/assets.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Configuration for asset pre-compilation.

# Keep test assets separate.
Rails.configuration.assets.prefix = '/assets-test' if Rails.env.test?

# Version of your assets, change this if you want to expire all your assets.
Rails.configuration.assets.version = '1.0'

# Handling of JavaScript and CSS are not done by the asset pipeline directly.
Rails.configuration.assets.js_compressor  = nil
Rails.configuration.assets.css_compressor = nil

# Add additional assets to the asset load path.
# Rails.configuration.assets.paths << Emoji.images_path

# Enable serving of images, stylesheets and JavaScripts from an asset server.
# Rails.configuration.asset_host = "http://assets.example.com"
