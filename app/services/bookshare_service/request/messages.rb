# app/services/bookshare_service/request/messages.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::Messages
#
# == Usage Notes
#
# === From API section 2.8 (Messages):
# Messages are notifications or alerts to users individually, or to all users
# associated with a Site. They are sent from a Membership Assistant or a
# system process, and not from user to user.
#
#--
# noinspection RubyParameterNamingConvention
#++
module BookshareService::Request::Messages

  include BookshareService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myMessages
  #
  # == 2.8.1. Get my messages
  # Request the list of messages that the user is able to see. These could be
  # specific to the user, or system-wide messages.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String] :status
  #
  # @return [Bs::Message::UserMessageList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-my-messages-list
  #
  def get_my_messages(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'myMessages', **opt)
    Bs::Message::UserMessageList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          status: String,
        },
        reference_id: '_get-my-messages-list'
      }
    end

  # == GET /v2/myMessages/{messageId}
  #
  # == 2.8.2. Get a message of mine
  # Request a message that the user is able to see. This could be specific to
  # the user, or a system-wide message.
  #
  # @param [String] messageId
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Bs::Message::UserMessage]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-my-message
  #
  def get_my_message(messageId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'myMessages', messageId, **opt)
    Bs::Message::UserMessage.new(response, error: exception)
  end
    .tap do |method|
    add_api method => {
      required: {
        messageId: String,
      },
      reference_id: '_get-my-message'
    }
  end

  # == PUT /v2/myMessages/{messageId}
  #
  # == 2.8.3. Mark message as read
  # As an individual member, mark a message of mine as read or unread.
  #
  # @param [String] messageId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [Boolean] :read       *REQUIRED*
  #
  # @return [Bs::Message::UserMessage]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-my-message
  #
  def update_my_message(messageId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:put, 'myMessages', messageId, **opt)
    Bs::Message::UserMessage.new(response, error: exception)
  end
    .tap do |method|
    add_api method => {
      required: {
        messageId: String,
        read:      Boolean,
      },
      reference_id:    '_put-my-message'
    }
  end

end

__loading_end(__FILE__)
