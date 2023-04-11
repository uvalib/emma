# app/records/search/message/retrieval_result.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search::Message::RetrievalResult
#
# @attr [String]        key
# @attr [Array<String>] messages
# @attr [Array<String>] links
#
class Search::Message::RetrievalResult < Search::Api::Message

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :key
    has_many  :messages
    has_many  :links
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
