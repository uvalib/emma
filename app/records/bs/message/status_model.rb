# app/records/bs/message/status_model.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::StatusModel
#
# @see Bs::Record::StatusModel
#
class Bs::Message::StatusModel < Bs::Api::Message

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
