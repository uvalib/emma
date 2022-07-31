# app/records/lookup/_remote_service/api/message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A module not a class so that in can be mixed in to the message class for
# an actual service in place of Api::Message.
#
module Lookup::RemoteService::Api::Message

  extend ActiveSupport::Concern

  include Api::Message

  include Lookup::RemoteService::Shared::ResponseMethods

  # noinspection RbsMissingTypeSignature
  included do

    # Initialize a new instance.
    #
    # @param [Faraday::Response, Exception Model, Hash, String, nil] src
    # @param [Hash, nil]                                             opt
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

end

__loading_end(__FILE__)
