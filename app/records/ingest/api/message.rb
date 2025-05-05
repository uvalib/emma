# app/records/ingest/api/message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for outbound messages to the EMMA Unified Ingest API.
#
class Ingest::Api::Message < Ingest::Api::Record

  include Api::Message

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
      apply_wrap!(opt)
      super(src, **opt)
    end
  end

end

__loading_end(__FILE__)
