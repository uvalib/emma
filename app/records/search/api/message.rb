# app/records/search/api/message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for inbound messages from the EMMA Unified Search API.
#
class Search::Api::Message < Search::Api::Record

  include ::Api::Message

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Hash, String] data
  # @param [Hash]                            opt
  #
  # This method overrides:
  # @see Search::Api::Record#initialize
  #
  def initialize(data, opt = nil)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      initialize_attributes
      super(data, opt)
    end
  end

end

__loading_end(__FILE__)
