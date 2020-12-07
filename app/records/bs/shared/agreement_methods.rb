# app/records/bs/shared/agreement_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to agreements.
#
# Attributes supplied by the including module:
#
# @attr [String] agreementId
#
module Bs::Shared::AgreementMethods

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Convert object to string.
  #
  # @return [String]
  #
  def to_s
    label
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A label for the item.
  #
  # @return [String]
  #
  def label
    identifier
  end

  # Return the unique identifier for the represented item.
  #
  # @return [String]
  #
  def identifier
    agreementId.to_s
  end

end

__loading_end(__FILE__)
