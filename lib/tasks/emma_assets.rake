# lib/tasks/emma_assets.rake
#
# frozen_string_literal: true
# warn_indent:           true
#
# Enhance the enhancements of 'assets:precompile' by 'cssbundling-rails' and
# 'jsbundling-rails' in order to pre-process .js.erb files.

unless defined?(ERB_ENHANCED)

  require 'erb'
  require 'emma/rake'

  ASSETS_ROOT = 'app/assets'
  JS_SRC      = 'javascripts'
  JS_DST      = 'builds'

  # ===========================================================================
  # Tasks
  # ===========================================================================

  namespace :emma_assets do

    ERB_ASSETS = %w(
      javascripts/shared/assets.js.erb
    )

    desc ['Pre-process .js.erb files', *ERB_ASSETS.map { |f| "- #{f}" }]
    task erb: [:environment] do
      ERB_ASSETS.each { |erb_file| preprocess_erb(erb_file) }
    end

  end

  # @private
  ERB_ENHANCED = Rake::Task['assets:precompile'].enhance(['emma_assets:erb'])

  # ===========================================================================
  # Methods
  # ===========================================================================

  public

  # Process an ERB asset source into the build directory.
  #
  # @param [String] src   Asset source file (with or without .erb suffix).
  # @param [String] dst   Derived if not provided.
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
