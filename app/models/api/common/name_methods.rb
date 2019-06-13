# app/models/api/common/name_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'sequence_methods'

# Methods mixed in to record elements related to user identities.
#
module Api::Common::NameMethods

  include Api::Common::SequenceMethods

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
    respond_to?(:name) ? name.to_s : identifier
  end

  # Return the unique identifier for the represented person.
  #
  # @return [String]
  #
  def identifier
    respond_to?(:username) ? username.to_s : emailAddress.to_s
  end

end

__loading_end(__FILE__)
