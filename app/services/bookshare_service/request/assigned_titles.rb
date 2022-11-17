# app/services/bookshare_service/request/assigned_titles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::AssignedTitles
#
# == Usage Notes
#
# === From API section 2.4 (Assigned Titles):
# Assigned titles are titles that have been assigned to an organization member
# by a sponsor of that organization.
#
#--
# noinspection RubyParameterNamingConvention, RubyLocalVariableNamingConvention
#++
module BookshareService::Request::AssignedTitles

  include BookshareService::Common
  include BookshareService::Testing

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myAssignedTitles
  #
  # == 2.4.1. Get my assigned titles
  # As an organization member, get titles that have been assigned to me.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]                :start
  # @option opt [Integer]               :limit        Default: 10
  # @option opt [BsMyAssignedSortOrder] :sortOrder    Default: 'title'
  # @option opt [BsSortDirection]       :direction    Default: 'asc'
  #
  # @return [Bs::Message::TitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-assigned-titles
  #
  def get_my_assigned_titles(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'myAssignedTitles', **opt)
    api_return(Bs::Message::TitleMetadataSummaryList)
  end
    .tap do |method|
      add_api method => {
        optional: {
          start:      String,
          limit:      Integer,
          sortOrder:  BsMyAssignedSortOrder,
          direction:  BsSortDirection,
        },
        reference_id: '_my-assigned-titles'
      }
    end

  # == GET /v2/assignedTitles/(userIdentifier)
  #
  # == 2.4.2. Get titles assigned to an organization member
  # As a sponsor or Membership Assistant, get a list of titles that have been
  # assigned to a particular organization member.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [String]              :start
  # @option opt [Integer]             :limit        Default: 10
  # @option opt [BsAssignedSortOrder] :sortOrder    Default: 'title'
  # @option opt [BsSortDirection]     :direction    Default: 'asc'
  #
  # @return [Bs::Message::AssignedTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_titles-assigned-member
  #
  def get_assigned_titles(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:get, 'assignedTitles', userId, **opt)
    api_return(Bs::Message::AssignedTitleMetadataSummaryList)
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
          sortOrder:      BsAssignedSortOrder,
          direction:      BsSortDirection,
        },
        reference_id:     '_titles-assigned-member'
      }
    end

  # == POST /v2/assignedTitles/(userIdentifier)
  #
  # == 2.4.3. Assign a title to an organization member
  # As a sponsor or Membership Assistant, assign a specific title to a
  # particular organization member.
  #
  # @param [User, String, nil] user         Default: `@user`.
  # @param [String]            bookshareId
  # @param [Hash]              opt          Passed to #api.
  #
  # @return [Bs::Message::AssignedTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-assign
  #
  def create_assigned_title(user: nil, bookshareId:, **opt)
    opt.merge!(bookshareId: bookshareId)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:post, 'assignedTitles', userId, **opt)
    api_return(Bs::Message::AssignedTitleMetadataSummaryList)
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

  # == DELETE /v2/assignedTitles/(userIdentifier)/(bookshareId)
  #
  # == 2.4.4. Un-assign a title for an organization member
  # As a sponsor or Membership Assistant, un-assign a specific title for a
  # particular organization member.
  #
  # @param [User, String, nil] user         Default: `@user`.
  # @param [String]            bookshareId
  # @param [Hash]              opt          Passed to #api.
  #
  # @return [Bs::Message::AssignedTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-unassign
  #
  def remove_assigned_title(user: nil, bookshareId:, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:delete, 'assignedTitles', userId, bookshareId, **opt)
    api_return(Bs::Message::AssignedTitleMetadataSummaryList)
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
