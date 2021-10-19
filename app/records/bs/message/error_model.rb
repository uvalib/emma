# app/records/bs/message/error_model.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::ErrorModel
#
# @see Bs::Record::StatusModel
# @see https://apidocs.bookshare.org/reference/index.html#_error_model
#
class Bs::Message::ErrorModel < Bs::Api::Message

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Bs::Record::StatusModel

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
    key.to_s
  end

end

__loading_end(__FILE__)
