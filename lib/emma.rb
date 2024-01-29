# lib/emma.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# This file is loaded from config/initializers/_extensions.rb.

require '_at_start'
require '_trace'

__loading_begin(__FILE__)

# This constant is defined to mark sections of code that are present only to
# give context information to RubyMine -- for example, "include" statements
# which allow RubyMine to indicate which methods are overrides.
#
# (This constant is required to be a non-false value.)
#
ONLY_FOR_DOCUMENTATION = true

# =============================================================================
# Loader methods - require
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
  return if relative_to.blank?
  dir = File.dirname(relative_to)
  patterns.flatten.compact_blank!.uniq.flat_map do |pattern|
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
  return if relative_to.blank?
  subdirs = patterns.flatten.compact_blank!.uniq
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
  return if filename.blank?
  directory = File.basename(filename, '.*')
  modules   = "#{directory}/*.rb"
  require_files(filename, modules)
end

# Require subclasses of the class defined by the current file which are in the
# same namespace (and stored in the subdirectory with the same base name).
#
# @param [String] filename            Normally supplied as __FILE__
#
# @return [void]
#
# @see #require_submodules
#
def require_subclasses(filename)
  require_submodules(filename)
end

# =============================================================================
# Loader methods - include
# =============================================================================

public

# Include submodules.
#
# @param [Class, Module] base         The class or module into which the
#                                       submodules will be included.
# @param [String, nil]   filename     If provided, first #require each file
#                                       from the subdirectory with the same
#                                       base name as *filename*.
# @param [bool]          and_extend   If *true* then also extend *base* with
#                                       the included modules.
#
# @return [Array<Module>]             The modules included into *base*.
#
# @yield [name, mod] Access the module before including in *base*.
# @yieldparam [Symbol] name
# @yieldparam [Module] mod
# @yieldreturn [bool] if *false* the module will not be included.
#
# @see #require_submodules
#
def include_submodules(base, filename = nil, and_extend: false)
  curr_constants = constants(false)
  if filename.present?
    # noinspection RubyMismatchedArgumentType
    require_submodules(filename)
    curr_constants = constants(false) - curr_constants
  end
  curr_constants.map { |name|
    mod = "#{self}::#{name}".safe_constantize
    next unless mod.is_a?(Module) && !mod.is_a?(Class)
    next unless !block_given? || yield(name, mod)
    base.include(mod)
    base.extend(mod) if and_extend
    mod
  }.compact
end

# Include and extend submodules.
#
# @see #include_submodules
#
def include_and_extend_submodules(base, filename = nil, &blk)
  include_submodules(base, filename, and_extend: true, &blk)
end

# =============================================================================
# Modules specific to the application namespace.
# =============================================================================

module Emma
end

# =============================================================================
# Require all modules from extensions and the "lib/emma" directory.
# =============================================================================

require '_system'
require '_loader'
require 'ext/active_support/ext'
require_submodules(__FILE__)
require 'ext'

# =============================================================================
# Desktop-only affordances
# =============================================================================

require '_desktop' if not_deployed?

__loading_end(__FILE__)
