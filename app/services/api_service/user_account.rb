# app/services/api_service/user_account.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::UserAccount
#
# == Usage Notes
#
# === From API section 2.6 (User Account):
# A user account represents a specific user who is known about by the
# Bookshare system.  Users may have various roles and other characteristics,
# which define the scope of possible features they have access to.  In general,
# a user will need to a have an active subscription to access titles, and in
# most cases will also need a proof of disability.
#
# Users can update certain information about themselves, while Membership
# Assistants or administrators will have access to see and modify the
# information about a larger collection of users; these are the endpoints that
# start with "/v2/accounts".  On those endpoints, a Membership Assistant is
# allowed to see and manage only those user accounts that are associated with
# their site, while administrators are allowed access to users across all
# sites.
#
# noinspection RubyParameterNamingConvention, RubyLocalVariableNamingConvention
module ApiService::UserAccount

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Hash{Symbol=>String}]
  USER_ACCOUNT_SEND_MESSAGE = {

    # TODO: e.g.:
    no_items:      'There were no items to request',
    failed:        'Unable to request items right now',

  }.reverse_merge(API_SEND_MESSAGE).freeze

  # @type [Hash{Symbol=>(String,Regexp,nil)}]
  USER_ACCOUNT_SEND_RESPONSE = {

    # TODO: e.g.:
    no_items:       'no items',
    failed:         nil

  }.reverse_merge(API_SEND_RESPONSE).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/me
  #
  # == 2.6.1. Get user identity
  # Request basic information about the current user.
  #
  # @return [ApiUserIdentity]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_me
  #
  def get_user_identity(*)
    api(:get, 'me')
    ApiUserIdentity.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        reference_id: '_me'
      }
    end

  # == GET /v2/myaccount
  #
  # == 2.6.2. Get my account summary
  # Get an account summary of the current user.
  #
  # @return [ApiMyAccountSummary]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-myaccount-summary
  #
  def get_my_account(*)
    api(:get, 'myaccount')
    ApiMyAccountSummary.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        reference_id: '_get-myaccount-summary'
      }
    end

  # == GET /v2/myaccount/history
  #
  # == 2.6.3. Get my account downloads
  # Get a listing of downloads made by the current user.
  #
  # @param [Hash] opt                 Optional API URL parameters.
  #
  # @option opt [Integer]          :limit
  # @option opt [HistorySortOrder] :sortOrder   Default: 'title'
  # @option opt [Direction2]       :direction   Default: 'desc'
  #
  # @return [ApiTitleDownloadList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-myaccount-downloads
  #
  def get_my_download_history(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'myaccount', 'history', **opt)
    ApiTitleDownloadList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          limit:      Integer,
          sortOrder:  HistorySortOrder,
          direction:  Direction2,
        },
        reference_id: '_get-myaccount-downloads'
      }
    end

  # ===========================================================================
  # :section: Preferences
  # ===========================================================================

  public

  # == GET /v2/myaccount/preferences
  #
  # == 2.6.4. Get my account preferences
  # Get the account preferences associated with the current user.
  #
  # @return [ApiMyAccountPreferences]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-myaccount-preferences
  #
  def get_my_preferences(*)
    api(:get, 'myaccount', 'preferences')
    ApiMyAccountPreferences.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        reference_id: '_get-myaccount-preferences'
      }
    end

  # == PUT /v2/myaccount/preferences
  #
  # == 2.6.5. Update my account preferences
  # Update the account preferences associated with the current user.
  #
  # @param [Hash] opt                 Optional API URL parameters.
  #
  # @option opt [Boolean]       :allowAdultContent
  # @option opt [Boolean]       :showAllBooks           Default: *false*
  # @option opt [IsoLanguage]   :language
  # @option opt [FormatType]    :format
  # @option opt [BrailleGrade]  :brailleGrade
  # @option opt [BrailleFormat] :brailleFormat
  # @option opt [Integer]       :brailleCellLineWidth
  # @option opt [Boolean]       :useUeb                 Default: *false*
  #
  # @return [ApiMyAccountPreferences]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-myaccount-preferences
  #
  def update_my_preferences(**opt)
    opt = get_parameters(__method__, **opt)
    api(:put, 'myaccount', 'preferences', **opt)
    ApiMyAccountPreferences.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          allowAdultContent:    Boolean,
          showAllBooks:         Boolean,
          language:             IsoLanguage,
          format:               FormatType,
          brailleGrade:         BrailleGrade,
          brailleFormat:        BrailleFormat,
          brailleCellLineWidth: Integer,
          useUeb:               Boolean,
        },
        reference_id:           '_put-myaccount-preferences'
      }
    end

  # ===========================================================================
  # :section: Recommendation profile
  # ===========================================================================

  public

  # == GET /v2/myaccount/recommendationProfile
  #
  # == 2.6.6. Get my recommendation profile
  # Get property choices that guide title recommendations for the current user.
  #
  # @return [ApiRecommendationProfile]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-my-recommendation-profile
  #
  def get_my_recommendation_profile(*)
    api(:get, 'myaccount', 'recommendationProfile')
    ApiRecommendationProfile.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        reference_id: '_get-my-recommendation-profile'
      }
    end

  # == PUT /v2/myaccount/recommendationProfile
  #
  # == 2.6.7. Update my recommendation profile
  # Update property choices that guide title recommendations for the current
  # user.
  #
  # @param [Hash] opt                 Optional API URL parameters.
  #
  # @option opt [Boolean]      :includeGlobalCollection   Default: *false*
  # @option opt [NarratorType] :narratorType
  # @option opt [Gender]       :narratorGender
  # @option opt [Integer]      :readingAge
  # @option opt [ContentWarning,Array<ContentWarning>] :excludedContentWarnings
  # @option opt [ContentWarning,Array<ContentWarning>] :includedContentWarnings
  # @option opt [String, Array<String>]                :excludedCategories
  # @option opt [String, Array<String>]                :includedCategories
  # @option opt [String, Array<String>]                :excludedAuthors
  # @option opt [String, Array<String>]                :includedAuthors
  #
  # @return [ApiRecommendationProfile]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-my-recommendation-profile
  #
  def update_my_recommendation_profile(**opt)
    opt = get_parameters(__method__, **opt)
    api(:put, 'myaccount', 'recommendationProfile', **opt)
    ApiRecommendationProfile.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          includeGlobalCollection: Boolean,
          narratorType:            NarratorType,
          narratorGender:          Gender,
          readingAge:              Integer,
          excludedContentWarnings: ContentWarning,
          includedContentWarnings: ContentWarning,
          excludedCategories:      String,
          includedCategories:      String,
          excludedAuthors:         String,
          includedAuthors:         String,
        },
        multi: %i[
          excludedContentWarnings  includedContentWarnings
          excludedCategories       includedCategories
          excludedAuthors          includedAuthors
        ],
        reference_id:              '_put-my-recommendation-profile'
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
    response_table = USER_ACCOUNT_SEND_RESPONSE
    message_table  = USER_ACCOUNT_SEND_MESSAGE
    message = request_error_message(method, response_table, message_table)
    raise Api::AccountError, message
  end

end

__loading_end(__FILE__)
