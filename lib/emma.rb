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
# @see #require_files
#
def require_subdirs(relative_to, *patterns)
  subdirs = patterns.flatten.reject(&:blank?).uniq
  subdirs << '' if subdirs.blank?
  subdirs.map! { |subdir| "#{subdir}/**/*.rb" }
  require_files(relative_to, *subdirs)
end

# Require the submodules for a file which are stored in the subdirectory with
# the same base name.
#
# @param [String] filename            Normally supplied as __FILE__
#
# @return [void]
#
# @see #require_files
#
def require_submodules(filename)
  directory = File.basename(filename, '.*')
  modules   = "#{directory}/*.rb"
  require_files(filename, modules)
end

# Include submodules.
#
# @param [Class, Module] base         The class or module into which the
#                                       submodules will be included.
# @param [String, nil]   filename     If provided, first #require each file
#                                       from the subdirectory with the same
#                                       base name as *filename*.
#
# @yield [name, mod] Access the module before including in *base*.
#   Use 'next' within the block to skip inclusion of that module.
# @yieldparam [Symbol] name
# @yieldparam [Module] mod
# @yieldreturn [void]
#
# @return [Array<Module>]           The modules included into *base*.
#
# @see #require_submodules
#
def include_submodules(base, filename = nil)
  curr_constants = constants(false)
  if filename
    require_submodules(filename)
    curr_constants = constants(false) - curr_constants
  end
  curr_constants.map { |name|
    mod = "#{self}::#{name}".constantize
    next unless mod.is_a?(Module) && !mod.is_a?(Class)
    yield(name, mod) if block_given?
    base.send(:include, mod)
    mod
  }.compact
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
require_submodules(__FILE__)
require 'ext'

__loading_end(__FILE__)
