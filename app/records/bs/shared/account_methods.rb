# app/records/bs/shared/account_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to user identities.
#
# Attributes supplied by the including module:
#
# @attr [String] emailAddress
# @attr [String] username
#
module Bs::Shared::AccountMethods

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Model
    # :nocov:
  end

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

  # ===========================================================================
  # :section: Model overrides
  # ===========================================================================

  public

  # Return the unique identifier for the represented person.
  #
  # @return [String]
  #
  def identifier
    (try(:username) || try(:emailAddress) || name).to_s
  end

end

__loading_end(__FILE__)
