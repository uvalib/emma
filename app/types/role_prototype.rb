# app/types/role_prototype.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Role prototypes.
#
# A "role prototype" (or, more casually, "role") is associated with a set of
# one or more RoleCapability values which characterize the functionalities for
# which a user with the given role is authorized.
#
# @see "en.emma.type.ability.RolePrototype"
# @see Ability
#
class RolePrototype < EnumType

  define_enumeration do
    Ability::PROTOTYPE_CONFIG.transform_values { _1[:label] }
  end

end

__loading_end(__FILE__)
