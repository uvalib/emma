# config/initializers/assets.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Configuration for asset pre-compilation.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Handling of JavaScript and CSS are not done by the asset pipeline directly.
Rails.application.config.assets.js_compressor  = nil
Rails.application.config.assets.css_compressor = nil

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Enable serving of images, stylesheets and JavaScripts from an asset server.
# config.asset_host = "http://assets.example.com"
