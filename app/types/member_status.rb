# app/types/member_status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A value for an account or organization which indicates the state of that
# entity with respect to EMMA membership standing.
#
# @see "en.emma.type.account.MemberStatus"
#
class MemberStatus < EnumType

  define_enumeration do
    ACCOUNT_TYPES[name.to_sym].transform_values { _1[:label] }
  end

end

__loading_end(__FILE__)
