# lib/emma.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# This file is loaded from config/initializers/_extensions.rb.

require '_at_start'
require '_trace'

__loading_begin(__FILE__)

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
  patterns.flatten.compact_blank.uniq.flat_map do |pattern|
    Dir.glob("#{dir}/#{pattern}")
      .reject  { [relative_to, dir].include?(_1) }
      .sort_by { [_1, _1.length] }
      .each    { require _1 }
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
def require_subdirs(relative_to, *patterns)
  return if relative_to.blank?
  subdirs = patterns.flatten.compact_blank.uniq
  subdirs << '' if subdirs.blank?
  subdirs.map! { "#{_1}/**/*.rb" }
  require_files(relative_to, *subdirs)
end

# Require the submodules for a file which are stored in the subdirectory with
# the same base name.
#
# @param [String] filename            Normally supplied as __FILE__
#
# @return [void]
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
def require_subclasses(filename)
  require_submodules(filename)
end

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
def include_submodules(base, filename = nil, and_extend: false)
  curr_constants = constants(false)
  if filename.present?
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
def include_and_extend_submodules(base, filename = nil, &blk)
  include_submodules(base, filename, and_extend: true, &blk)
end

# =============================================================================
# Loader methods - metaprogramming
# =============================================================================

public

# Get the named parameters of the given method.
#
# @param [Symbol meth
# @param [Array<Symbol>] types
#
# @return [Array<Symbol>]
#
# == Usage Notes
# In principle this should work in any context, but it's only been used for
# the purpose of creating constants within module definitions.
#
def method_key_params(meth, types: %i[key keyreq])
  [self, self.class].each do |tgt|
    %i[method instance_method].each do |op|
      if tgt.try(op.to_s.pluralize)&.include?(meth)
        parameters = tgt.send(op, meth).parameters
        return parameters.map { |(t, name)| name if types.include?(t) }.compact
      end
    end
  end
  raise "no #{meth.inspect} for class #{self.class} or self #{self}"
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
require '_configuration'
require '_constants'
require '_loader'
require 'ext/active_support/ext'
require_submodules(__FILE__)
require 'ext'

# =============================================================================
# Desktop-only affordances
# =============================================================================

require '_desktop' if not_deployed?

__loading_end(__FILE__)
