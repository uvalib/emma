# lib/_loader.rb
#
# frozen_string_literal: true
# warn_indent:           true

require '_configuration'
require '_trace'

__loading_begin(__FILE__)

# =============================================================================
# Constants
# =============================================================================

# Control prepending of override definitions from 'lib/ext/*/*.rb'.
#
# During normal operation this should be set to *true*.  Change the default
# value here or override dynamically with the environment variable.
#
# NOTE: setting to *false* should be for experimentation only since it will
#   result in untested execution paths.
#
IMPLEMENT_OVERRIDES = !false?(ENV_VAR['IMPLEMENT_OVERRIDES'])

unless IMPLEMENT_OVERRIDES
  Log.warn("IMPLEMENT_OVERRIDES = #{IMPLEMENT_OVERRIDES.inspect}")
end

# =============================================================================
# Loader methods
# =============================================================================

# This method can be used as a simple mechanism to override member(s) of a
# class or module by supplying new methods or redefinitions of existing methods
# within a block that is prepended as an anonymous module.
#
# @param [Hash, Class, Module] mod    The class or module to override
# @param [Module, nil]         mod2   Module to prepend to *mod*.
# @param [Proc]                blk    Passed to Module#new.
#
# @raise [RuntimeError]               Only for a non-deployed instance.
#
# @return [void]
#
#--
# === Variations
#++
#
# @overload override mod => mod2
#   Used outside of the definition of *mod2* to override *mod* definitions.
#
# @overload override mod => mod2, mod3 => mod4, ...
#   Multiple overrides.
#
# @overload override(mod, mod2)
#   Alternate syntax for a single override.
#
# @overload override(mod)
#   Given within the definition of *mod2* to override definitions in *mod*.
#   NOTE: This may not work in all situations.
#
# @overload override(mod) { METHOD_DEFINITIONS }
#   The block contains definitions to override *mod* definitions by
#   prepending an anonymous module.
#   NOTE: This may not work in all situations.
#
# === Usage Notes
# Within the block given, define new methods that *mod* will respond to and/or
# redefine existing methods.  Within redefined methods, "super" refers to the
# original method.
#
def override(mod, mod2 = nil, &blk)
  unless IMPLEMENT_OVERRIDES
    Rails.logger.warn("Override of #{mod} suppressed by configuration.")
    return # Nothing in *block* will be executed.
  end
  errors = []
  overrides =
    if mod.is_a?(Hash)
      # One or more override mappings.
      errors << 'block invalid'    if blk
      errors << "#{mod2}: invalid" if mod2.present?
      mod

    elsif blk
      # Override definitions from a block.
      errors << "#{mod2}: invalid" if mod2.present?
      { mod => Module.new(&blk) }

    elsif mod2.present?
      # A single override mapping.
      { mod => mod2 }

    else
      errors << 'no override module given'

    end
  if errors.present?
    Rails.logger.error((error = errors.join('; ')))
    raise error if not_deployed?
  end
  overrides.each_pair do |target, new_definitions|
    target.send(:prepend, new_definitions)
  end
end

# Alternate syntax which does not expect a block (so braces will be interpreted
# as part of the hash argument).
#
# @param [Hash{Module=>Module}] mapping   Override mappings.
#
# @return [void]
#
def overrides(mapping)
  if IMPLEMENT_OVERRIDES
    override(mapping)
  else
    Rails.logger.warn("Overrides suppressed by configuration: #{mapping}")
  end
end

__loading_end(__FILE__)
