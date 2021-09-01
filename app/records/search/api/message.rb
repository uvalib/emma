# app/records/search/api/message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for inbound messages from the EMMA Unified Search API.
#
class Search::Api::Message < Search::Api::Record

  include Api::Message

  include Search::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Model, Hash, String, nil] src
  # @param [Hash, nil]                                   opt
  #
  def initialize(src, opt = nil)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      initialize_attributes unless src.is_a?(Model)
      super(src, **opt)
      initialize_exec_report(exception)
    end
  end

end

__loading_end(__FILE__)
