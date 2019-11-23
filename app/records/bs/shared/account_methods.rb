# app/records/bs/shared/account_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to user identities.
#
module Bs::Shared::AccountMethods

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Convert object to string.
  #
  # @return [String]
  #
  def to_s
    identifier
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A label for the represented person.
  #
  # @return [String]
  #
  def label
    name.to_s
  end

  # Return the unique identifier for the represented person.
  #
  # @return [String]
  #
  def identifier
    result   = (username     if respond_to?(:username))
    result ||= (emailAddress if respond_to?(:emailAddress))
    result ||= name
    result.to_s
  end

end

__loading_end(__FILE__)
