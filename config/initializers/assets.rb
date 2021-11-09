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

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

# Compress JavaScripts and CSS.
Rails.application.config.assets.css_compressor = :scss
# noinspection SpellCheckingInspection
Rails.application.config.assets.js_compressor =
  Terser.new(
    compress: {
      hoist_funs: false
    }
  )
