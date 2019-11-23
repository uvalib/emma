# app/services/bookshare_service/request/assigned_titles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::AssignedTitles
#
# == Usage Notes
#
# === From API section 2.4 (Assigned Titles):
# Assigned titles are titles that have been assigned to an organization member
# by a sponsor of that organization.
#
# noinspection RubyParameterNamingConvention, RubyLocalVariableNamingConvention
module BookshareService::Request::AssignedTitles

  include BookshareService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myAssignedTitles
  #
  # == 2.4.1. Get my assigned titles
  # Get the titles assigned to the current user (organization member).
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]              :start
  # @option opt [Integer]             :limit        Default: 10
  # @option opt [MyAssignedSortOrder] :sortOrder    Default: 'title'
  # @option opt [Direction]           :direction    Default: 'asc'
  #
  # @return [Bs::Message::TitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-assigned-titles
  #
  def get_my_assigned_titles(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'myAssignedTitles', **opt)
    Bs::Message::TitleMetadataSummaryList.new(response, error: exception)
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
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [String]            :start
  # @option opt [Integer]           :limit        Default: 10
  # @option opt [AssignedSortOrder] :sortOrder    Default: 'title'
  # @option opt [Direction]         :direction    Default: 'asc'
  #
  # @return [Bs::Message::AssignedTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_titles-assigned-member
  #
  def get_assigned_titles(user: @user, **opt)
    userIdentifier = name_of(user)
    opt = get_parameters(__method__, **opt)
    api(:get, 'assignedTitles', userIdentifier, **opt)
    Bs::Message::AssignedTitleMetadataSummaryList.new(response, error: exception)
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
  # @param [Hash]              opt          Passed to #api.
  #
  # @return [Bs::Message::AssignedTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-assign
  #
  def create_assigned_title(user: @user, bookshareId:, **opt)
    userIdentifier = name_of(user)
    opt = opt.merge(bookshareId: bookshareId)
    api(:post, 'assignedTitles', userIdentifier, **opt)
    Bs::Message::AssignedTitleMetadataSummaryList.new(response, error: exception)
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
  # @param [Hash]              opt          Passed to #api.
  #
  # @return [Bs::Message::AssignedTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-unassign
  #
  def remove_assigned_title(user: @user, bookshareId:, **opt)
    userIdentifier = name_of(user)
    opt = opt.merge(bookshareId: bookshareId)
    api(:delete, 'assignedTitles', userIdentifier, **opt)
    Bs::Message::AssignedTitleMetadataSummaryList.new(response, error: exception)
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

end

__loading_end(__FILE__)
