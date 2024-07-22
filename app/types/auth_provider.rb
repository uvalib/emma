# app/types/auth_provider.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A symbolic indication of an authentication source.
#
# @note Currently this is only :shibboleth and may not be especially useful.
#
# @see AUTH_PROVIDERS
#
class AuthProvider < EnumType

  define_enumeration do
    AUTH_PROVIDERS.map { |auth| [auth, auth.to_s.titleize] }.to_h
  end

end

__loading_end(__FILE__)
