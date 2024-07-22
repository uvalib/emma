# app/types/true_false.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# TrueFalse
#
# @see "en.emma.type.generic.TrueFalse"
#
class TrueFalse < EnumType

  define_enumeration(GENERIC_TYPES[name.to_sym])

end

__loading_end(__FILE__)
