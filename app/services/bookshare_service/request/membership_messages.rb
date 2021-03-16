# app/services/bookshare_service/request/membership_messages.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::MembershipMessages
#
# == Usage Notes
#
# === From Membership Management API 2.4 (Membership Assistant - Messages):
# Membership Assistant users are able to create and manage system and
# informational messages sent to either a given user account, or to all members
# of the Assistant’s site.
#
#--
# noinspection RubyParameterNamingConvention, RubyLocalVariableNamingConvention
#++
module BookshareService::Request::MembershipMessages

  include BookshareService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/messages
  #
  # == 2.4.1. Get a list of messages
  # As a membership assistant, get a list of messages based on the inputs given.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [User, String]       :userIdentifier
  # @option opt [User, String]       :user          Alias for :userIdentifier
  # @option opt [BsMessageType]      :messageType
  # @option opt [BsMessageSortOrder] :sortOrder     Default: 'dateCreated'
  # @option opt [BsSortDirection]    :direction     Default: 'asc'
  #
  # @return [Bs::Message::UserMessageDetailList]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_get-messages
  #
  def get_messages(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'messages', **opt)
    Bs::Message::UserMessageDetailList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        optional: {
          userIdentifier: String,
          messageType:    BsMessageType,
          sortOrder:      BsMessageSortOrder,
          direction:      BsSortDirection,
        },
        reference_page:   'membership',
        reference_id:     '_get-messages'
      }
    end

  # == POST /v2/messages
  #
  # == 2.4.2. Create a message
  # Create a new message. This could be specific to a user, or a system-wide
  # message for all users of the site.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]            :text                           *REQUIRED*
  # @option opt [BsMessagePriority] :messagePriority                *REQUIRED*
  # @option opt [BsMessageType]     :messageType                    *REQUIRED*
  # @option opt [IsoDay]            :expirationDate                 *REQUIRED*
  # @option opt [User, String]      :userIdentifier
  # @option opt [User, String]      :user             Alias for :userIdentifier
  #
  # @return [Bs::Message::UserMessageDetail]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_post-message
  #
  def create_message(**opt)
    opt = get_parameters(__method__, **opt)
    api(:post, 'messages', **opt)
    Bs::Message::UserMessageDetail.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:             :userIdentifier,
        },
        required: {
          text:             String,
          messagePriority:  String,
          messageType:      String,
          expirationDate:   String,
        },
        optional: {
          userIdentifier:   String,
        },
        reference_page:     'membership',
        reference_id:       '_post-message'
      }
    end

  # == PUT /v2/messages/(messageId)
  #
  # == 2.4.3. Update a message
  # As a membership assistant, update a message.
  #
  # @param [String] messageId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [Boolean] :read       *REQUIRED*
  #
  # @return [Bs::Message::UserMessageDetail]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_put-message
  #
  def update_message(messageId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:put, 'messages', messageId, **opt)
    Bs::Message::UserMessageDetail.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          messageId:    String,
          read:         Boolean,
        },
        reference_page: 'membership',
        reference_id:   '_put-message'
      }
    end

  # == DELETE /v2/messages/(messageId)
  #
  # == 2.4.4. Expire a message
  # As a membership assistant, expire a message.
  #
  # @param [String] messageId
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [void]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_delete-message
  #
  def expire_message(messageId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:put, 'messages', messageId, **opt)
  end
    .tap do |method|
    add_api method => {
      required: {
        messageId:    String,
      },
      reference_page: 'membership',
      reference_id:   '_delete-message'
    }
  end

end

__loading_end(__FILE__)
