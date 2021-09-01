# app/records/bs/message/status_model.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::StatusModel
#
# @attr [String]        key
# @attr [Array<String>] messages
#
# @see https://apidocs.bookshare.org/reference/index.html#_status_model
#
# @see Bs::Record::StatusModel (duplicate schema)
#
class Bs::Message::StatusModel < Bs::Api::Message

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :key
    has_many  :messages
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
