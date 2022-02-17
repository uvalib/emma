# lib/tasks/emma_assets.rake
#
# frozen_string_literal: true
# warn_indent:           true
#
# Enhancements to 'assets:precompile'.

namespace :emma_assets do

  # Set to *false* to avoid post-processing the CSS source map.
  #
  # @note This should be for both desktop and deployed assets.
  #
  FIX_CSS_MAP = true

  # Set to *false* to avoid making a copy of CSS/SCSS source files on the
  # desktop development system.
  #
  # @note This should only be done on the desktop.
  #
  BACKUP_CSS_SOURCES = !application_deployed?

  # ===========================================================================
  # Tasks
  # ===========================================================================

  desc ['Post-process CSS sourcemap', 'Replaces file:// with file://C:']
  task fix_css_map: [:environment] do
    $stderr.puts
    backup_css_sources if BACKUP_CSS_SOURCES
    edit_source_map    if FIX_CSS_MAP
    $stderr.puts
  end

  # ===========================================================================
  # Methods
  # ===========================================================================

  public

  CSS_SOURCE_MAP = 'app/assets/builds/application.css.map'
  CSS_SRC_DIR    = 'app/assets/stylesheets'
  DEV_ROOT       = ENV.fetch('DEV_ROOT') { Rails.root.to_s }
  CSS_DST_ROOT   = "/C#{DEV_ROOT}"
  CSS_DST_DIR    = "#{CSS_DST_ROOT}/#{CSS_SRC_DIR}"

  # Replace "file:///" references with "file://C:/".
  #
  # @param [String] file                CSS source map.
  #
  # @note This assumes that 'sass' is run with '--source-map-urls=absolute'
  #
  def edit_source_map(file = CSS_SOURCE_MAP)
    $stderr.puts '*** Transform CSS source map'
    cur_root = "#{Rails.root}/".gsub(%r{/}, '\\/')
    dev_root = "C:#{DEV_ROOT}/".gsub(%r{/}, '\\/')
    run <<~HEREDOC
      sed -E --in-place 's/(file:\\/\\/)#{cur_root}/\\1#{dev_root}/g' '#{file}'
    HEREDOC
  end

  # Backup CSS source files for use with source maps.
  #
  # @param [String] src_dir             Asset source directory.
  # @param [String] dst_dir             Copy of asset source directory.
  #
  # @return [void]
  #
  # @note This allows CSS source maps to be usable from the desktop
  #   development system even from a web console to the deployed instance
  #   since the absolute path will be resolved by the browser.
  #
  def backup_css_sources(src_dir = CSS_SRC_DIR, dst_dir = CSS_DST_DIR)
    $stderr.puts '*** Backup CSS sources (desktop only)'
    dst_dir ||= "#{CSS_DST_ROOT}/#{src_dir}"
    bg_run <<~HEREDOC
      mkdir -p '#{dst_dir}'
      cp --archive --update #{src_dir}/* #{dst_dir}
    HEREDOC
  end

  # ===========================================================================
  # Methods
  # ===========================================================================

  private

  # Run a sequence of shell commands in the background.
  #
  # @param [Array<String>] command    Individual shell commands with arguments.
  #
  def bg_run(*command, &block)
    run(*command, async: true, &block)
  end

  # Run a sequence of shell commands.
  #
  # @param [Array<String>] command    Individual shell commands with arguments.
  # @param [Boolean]       async      If *true*, run in the background.
  #
  def run(*command, async: false)
    command += Array.wrap(yield) if block_given?
    # noinspection RubyMismatchedReturnType
    command  = command.flat_map { |c| c.is_a?(String) ? c.split("\n") : c }
    command.map! { |cmd| cmd.to_s.strip.sub(/\s*(&&|;)$/, '') }.compact_blank!
    subshell = command.many? && async
    command  = command.join(' && ')
    command  = "(#{command})" if subshell
    command  = "#{command} &" if async
    sh(command)
  end

end

Rake::Task['assets:precompile'].enhance(['emma_assets:fix_css_map'])
