# lib/emma.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# This file is loaded from config/initializers/_extensions.rb.

require '_trace'

__loading_begin(__FILE__)

# =============================================================================
# Loader methods
# =============================================================================

public

# Require files via one or more "glob" patterns.
#
# @param [String] relative_to         Normally supplied as __FILE__
# @param [Array<String>] patterns     One or more relative paths; each path may
#                                       include "glob" patterns to specify
#                                       multiple files.
#
# @return [void]
#
# @see Dir#glob
#
def require_files(relative_to, *patterns)
  dir = File.dirname(relative_to)
  patterns.flatten.reject(&:blank?).uniq.flat_map do |pattern|
    Dir.glob("#{dir}/#{pattern}")
      .reject  { |path| (path == relative_to) || (path == dir) }
      .sort_by { |path| [path, path.length] }
      .each    { |path| require path }
  end
end

# Require subdirectories via one or more "glob" patterns.
#
# @param [String] relative_to         Normally supplied as __FILE__
# @param [Array<String>] patterns     One or more relative paths; each path may
#                                       include "glob" patterns to specify
#                                       multiple files.
#
# @return [void]
#
# @see Dir#glob
#
def require_subdir(relative_to, *patterns)
  subdirs = patterns.flatten.reject(&:blank?).uniq
  subdirs << '' if subdirs.blank?
  # noinspection RubyNilAnalysis
  subdirs.map! { |subdir| "#{subdir}/**/*.rb" }
  require_files(relative_to, subdirs)
end

# =============================================================================
# Modules specific to the application namespace.
# =============================================================================

module Emma
end

# =============================================================================
# Require all modules from extensions and the "lib/emma" directory.
# =============================================================================

require 'ext/active_support/ext'
require_subdir(__FILE__, 'emma')
require 'ext'

__loading_end(__FILE__)
