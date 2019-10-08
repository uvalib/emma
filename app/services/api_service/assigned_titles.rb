# app/services/api_service/assigned_titles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::AssignedTitles
#
# == Usage Notes
#
# === From API section 2.4 (Assigned Titles):
# Assigned titles are titles that have been assigned to an organization member
# by a sponsor of that organization.
#
# noinspection RubyParameterNamingConvention, RubyLocalVariableNamingConvention
module ApiService::AssignedTitles

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Hash{Symbol=>String}]
  ASSIGNED_TITLES_SEND_MESSAGE = {

    # TODO: e.g.:
    no_items:      'There were no items to request',
    failed:        'Unable to request items right now',

  }.reverse_merge(API_SEND_MESSAGE).freeze

  # @type [Hash{Symbol=>(String,Regexp,nil)}]
  ASSIGNED_TITLES_SEND_RESPONSE = {

    # TODO: e.g.:
    no_items:       'no items',
    failed:         nil

  }.reverse_merge(API_SEND_RESPONSE).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myAssignedTitles
  #
  # == 2.4.1. Get my assigned titles
  # Get the titles assigned to the current user (organization member).
  #
  # @param [Hash] opt                 Optional API URL parameters.
  #
  # @option opt [String]              :start
  # @option opt [Integer]             :limit        Default: 10
  # @option opt [MyAssignedSortOrder] :sortOrder    Default: 'title'
  # @option opt [Direction]           :direction    Default: 'asc'
  #
  # @return [ApiTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-assigned-titles
  #
  def get_my_assigned_titles(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'myAssignedTitles', **opt)
    ApiTitleMetadataSummaryList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          start:      String,
          limit:      Integer,
          sortOrder:  MyAssignedSortOrder,
          direction:  Direction,
        },
        reference_id: '_my-assigned-titles'
      }
    end

  # == GET /v2/assignedTitles/{userIdentifier}
  #
  # == 2.4.2. Get titles assigned to an organization member
  # Get a list of titles assigned to the specified organization member.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Optional API URL parameters.
  #
  # @option opt [String]            :start
  # @option opt [Integer]           :limit        Default: 10
  # @option opt [AssignedSortOrder] :sortOrder    Default: 'title'
  # @option opt [Direction]         :direction    Default: 'asc'
  #
  # @return [ApiAssignedTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_titles-assigned-member
  #
  def get_assigned_titles(user: @user, **opt)
    userIdentifier = name_of(user)
    opt = get_parameters(__method__, **opt)
    api(:get, 'assignedTitles', userIdentifier, **opt)
    ApiAssignedTitleMetadataSummaryList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
        },
        optional: {
          start:          String,
          limit:          Integer,
          sortOrder:      AssignedSortOrder,
          direction:      Direction,
        },
        reference_id:     '_titles-assigned-member'
      }
    end

  # == POST /v2/assignedTitles/{userIdentifier}
  #
  # == 2.4.3. Assign a title to an organization member
  # As a sponsor or Membership Assistant, assign a specific title to a
  # particular organization member.
  #
  # @param [User, String, nil] user         Default: @user
  # @param [String]            bookshareId
  #
  # @return [ApiAssignedTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-assign
  #
  def create_assigned_title(user: @user, bookshareId:)
    userIdentifier = name_of(user)
    opt = { bookshareId: bookshareId }
    api(:post, 'assignedTitles', userIdentifier, **opt)
    ApiAssignedTitleMetadataSummaryList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          bookshareId:    String,
        },
        reference_id:     '_title-assign'
      }
    end

  # == DELETE /v2/assignedTitles/{userIdentifier}/{bookshareId}
  #
  # == 2.4.4. Un-assign a title for an organization member
  # As a sponsor or Membership Assistant, un-assign a specific title for a
  # particular organization member.
  #
  # @param [User, String, nil] user         Default: @user
  # @param [String]            bookshareId
  #
  # @return [ApiAssignedTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-unassign
  #
  def remove_assigned_title(user: @user, bookshareId:)
    userIdentifier = name_of(user)
    opt = { bookshareId: bookshareId }
    api(:delete, 'assignedTitles', userIdentifier, **opt)
    ApiAssignedTitleMetadataSummaryList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          bookshareId:    String,
        },
        reference_id:     '_title-unassign'
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # raise_exception
  #
  # @param [Symbol, String] method    For log messages.
  #
  # This method overrides:
  # @see ApiService::Common#raise_exception
  #
  def raise_exception(method)
    response_table = ASSIGNED_TITLES_SEND_RESPONSE
    message_table  = ASSIGNED_TITLES_SEND_MESSAGE
    message = request_error_message(method, response_table, message_table)
    raise Api::AccountError, message
  end

end

__loading_end(__FILE__)
