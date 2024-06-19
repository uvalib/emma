# lib/_at_start.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Loaded before all Emma-related definitions.

# =============================================================================
# System extension support
# =============================================================================

public

# This is the reference used by SystemExtension#check_extension to determine
# the original definitions of the class or module being extended.
#
# Because this needs to be defined before getting into any of the 'lib/emma'
# code, the list of things need to be saved here needs to be updated manually
# to reflect the cases where SystemExtension is included.
#
# @type [Hash{Module=>Array<Symbol>}]
#
NATIVE_METHODS =
  if sanity_check?
    [Module, NilClass, Object, Array, Hash].map { |mod|
      defined = (mod.methods + mod.instance_methods).sort.uniq
      [mod, defined.freeze]
    }.to_h.freeze
  end
