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
  # @param [Faraday::Response, Api::Record, Hash, String, nil] src
  # @param [Hash]                                              opt
  #
  def initialize(src, **opt)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      initialize_attributes unless src.is_a?(Api::Record)
      super(src, **opt)
    end
  end

end

__loading_end(__FILE__)
