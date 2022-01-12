# config/initializers/assets.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Configuration for asset pre-compilation.
#
# NOTE: This includes option settings needed to get Uglifier to work for ES6.
# @see Uglifier#DEFAULTS

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Handling of JavaScript and CSS are not done by the asset pipeline directly.
Rails.application.config.assets.js_compressor  = nil
Rails.application.config.assets.css_compressor = nil
