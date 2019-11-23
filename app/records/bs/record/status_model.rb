# app/records/bs/record/status_model.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::StatusModel
#
# @attr [String]        key
# @attr [Array<String>] messages
#
# @see https://apidocs.bookshare.org/reference/index.html#_status_model
#
# NOTE: This duplicates:
# @see Bs::Message::StatusModel
#
class Bs::Record::StatusModel < Bs::Api::Record

  schema do
    attribute :key,      String
    has_many  :messages, String
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
