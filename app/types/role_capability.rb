# app/types/role_capability.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Role capabilities.
#
# A "role capability" describes a user-level ability which implies a set of
# lower-level functionalities (e.g. CRUD on a particular database table).
#
# @see "en.emma.type.ability.RoleCapability"
# @see Ability
#
class RoleCapability < EnumType

  define_enumeration do
    Ability::CAPABILITY_CONFIG.transform_values { _1[:label] }
  end

end

__loading_end(__FILE__)
