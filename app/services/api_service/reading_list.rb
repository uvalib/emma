# app/services/api_service/reading_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_common'

class ApiService

  module ReadingList

    include Common

    # @type [Hash{Symbol=>String}]
    READING_LIST_SEND_MESSAGE = {

      # TODO: e.g.:
      no_items:      'There were no items to request',
      failed:        'Unable to request items right now',

    }.reverse_merge(API_SEND_MESSAGE).freeze

    # @type [Hash{Symbol=>(String,Regexp,nil)}]
    READING_LIST_SEND_RESPONSE = {

      # TODO: e.g.:
      no_items:       'no items',
      failed:         nil

    }.reverse_merge(API_SEND_RESPONSE).freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # get_my_reading_lists
    #
    # @param [Hash, nil] opt
    #
    # @return [ApiReadingListList]
    #
    def get_my_reading_lists(**opt)
      api(:get, 'mylists', opt)
      data = response&.body&.presence
      ApiReadingListList.new(data, error: @exception)
    end

    # create_reading_list
    #
    # @param [String]    name
    # @param [Hash, nil] opt
    #
    # @return [ApiReadingList]
    #
    def create_reading_list(name:, **opt)
      opt = opt.reverse_merge(name: name)
      api(:post, 'mylists', opt)
      data = response&.body&.presence
      ApiReadingList.new(data, error: @exception)
    end

    # subscribe_reading_list
    #
    # @param [String]    readingListId
    # @param [Hash, nil] opt
    #
    # @return [ApiReadingListUserView]
    #
    def subscribe_reading_list(readingListId:, **opt)
      opt = opt.reverse_merge(enabled: true)
      api(:put, 'mylists', readingListId, 'subscription', opt)
      data = response&.body&.presence
      ApiReadingListUserView.new(data, error: @exception)
    end

    # unsubscribe_reading_list
    #
    # @param [String]    readingListId
    # @param [Hash, nil] opt
    #
    # @return [ApiReadingListUserView]
    #
    def unsubscribe_reading_list(readingListId:, **opt)
      opt = opt.reverse_merge(enabled: false)
      api(:put, 'mylists', readingListId, 'subscription', opt)
      data = response&.body&.presence
      ApiReadingListUserView.new(data, error: @exception)
    end

    # update_reading_list
    #
    # @param [String]    readingListId
    # @param [Hash, nil] opt
    #
    # @return [ApiReadingList]
    #
    def update_reading_list(readingListId:, **opt)
      api(:put, 'lists', readingListId, opt)
      data = response&.body&.presence
      ApiReadingList.new(data, error: @exception)
    end

    # get_reading_list_titles
    #
    # @param [String]    readingListId
    # @param [Hash, nil] opt
    #
    # @return [ApiReadingListTitlesList]
    #
    def get_reading_list_titles(readingListId:, **opt)
      api(:get, 'mylists', readingListId, 'titles', opt)
      data = response&.body&.presence
      ApiReadingListTitlesList.new(data, error: @exception)
    end

    # create_reading_list_title
    #
    # @param [String]    readingListId
    # @param [String]    bookshareId
    # @param [Hash, nil] opt
    #
    # @return [ApiReadingListTitlesList]
    #
    def create_reading_list_title(readingListId:, bookshareId:, **opt)
      opt = opt.reverse_merge(bookshareId: bookshareId)
      api(:post, 'lists', readingListId, 'titles', opt)
      data = response&.body&.presence
      ApiReadingListTitlesList.new(data, error: @exception)
    end

    # remove_reading_list_title
    #
    # @param [String]    readingListId
    # @param [String]    bookshareId
    # @param [Hash, nil] opt
    #
    # @return [ApiReadingListTitlesList]
    #
    def remove_reading_list_title(readingListId:, bookshareId:, **opt)
      opt = opt.reverse_merge(bookshareId: bookshareId)
      api(:delete, 'lists', readingListId, 'titles', opt)
      data = response&.body&.presence
      ApiReadingListTitlesList.new(data, error: @exception)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # raise_exception
    #
    # @param [Symbol, String] method  For log messages.
    #
    # This method overrides:
    # @see ApiService::Common#raise_exception
    #
    def raise_exception(method)
      response_table = READING_LIST_SEND_RESPONSE
      message_table  = READING_LIST_SEND_MESSAGE
      message = request_error_message(method, response_table, message_table)
      raise Api::ReadingListError, message
    end

  end

end

__loading_end(__FILE__)
