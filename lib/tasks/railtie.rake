# lib/tasks/railtie.rake
#
# frozen_string_literal: true
# warn_indent:           true
#
# Tasks in this file are included in Rakefile as part of EmmaRailtie so that
# they may be run first before any gems that enhance rake tasks.

EMMA_RAILTIE_RAKE ||= begin

  # EMMA uses `ENV['DATABASE']` for its own purposes, which do not coincide
  # with what "railties:install:migration" expects.  Since this clash is
  # specific to that task (i.e., nothing else in Rails looks for this
  # environment variable), it is deleted prior to running the task (rather than
  # coming up with an alternative environment variable name to use within EMMA
  # and its Terraform configurations).

  namespace 'emma:fix' do

    task migrations: [:environment] do
      ENV.delete('DATABASE')
    end

  end

  Rake::Task['railties:install:migrations'].enhance(['emma:fix:migrations'])

  # Enhance the enhancements of 'assets:precompile' by 'cssbundling-rails'
  # and 'jsbundling-rails' in order to pre-process .js.erb files.

  namespace 'emma:assets' do

    require 'erb'
    require 'emma_rake'

    # =========================================================================
    # Tasks
    # =========================================================================

    ERB_ASSETS = %w[javascripts/shared/assets.js.erb].freeze

    desc ['Pre-process .js.erb files', *ERB_ASSETS.map { |f| "- #{f}" }]
    task erb: [:environment] do
      ERB_ASSETS.each { |erb_file| preprocess_erb(erb_file) }
    end

    # =========================================================================
    # Methods
    # =========================================================================

    public

    ASSETS_ROOT = 'app/assets'
    JS_SRC      = 'javascripts'
    JS_DST      = 'builds'

    # Process an ERB asset source into the build directory.
    #
    # @param [String] src     Asset source file (with or without .erb suffix).
    # @param [String] dst     Derived if not provided.
    #
    # @return [void]
    #
    def preprocess_erb(src, dst = nil)
      src   = src.delete_prefix('/')
      src   = src.delete_prefix("#{ASSETS_ROOT}/").delete_prefix("#{JS_SRC}/")
      src   = "#{JS_SRC}/#{src}".delete_suffix('.erb')

      dst &&= dst.delete_prefix('/')
      dst &&= dst.delete_prefix("#{ASSETS_ROOT}/").delete_prefix("#{JS_DST}/")
      dst ||= src

      dst   = "#{ASSETS_ROOT}/#{JS_DST}/#{dst.tr('/', '-')}"
      src   = "#{ASSETS_ROOT}/#{src}.erb"

      file  = File.read(src)
      erb   = ERB.new(file, trim_mode: '<>').tap { |erb| erb.filename = src }
      data  = erb.result
      File.write(dst, data)
    end

  end

  Rake::Task['assets:precompile'].enhance(['emma:assets:erb'])

end
