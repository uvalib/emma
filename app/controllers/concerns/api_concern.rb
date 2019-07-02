# app/controllers/concerns/api_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiConcern
#
module ApiConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'ApiConcern')
  end

  include ApiHelper

  # ===========================================================================
  # :section: Initialization
  # ===========================================================================

  if Log.info?
    extend TimeHelper
    # Log API request times.
    ActiveSupport::Notifications.subscribe('request.faraday') do |*args|
      _name    = args.shift # 'request.faraday'
      starts   = args.shift
      ends     = args.shift
      _payload = args.shift
      env      = args.shift
      method   = env[:method].to_s.upcase
      url      = env[:url]
      host     = url.host
      uri      = url.request_uri
      duration = time_span(starts.to_f, ends.to_f)
      Log.info { '[%s] %s %s (%s)' % [host, method, uri, duration] }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return account summary information and account preferences.
  #
  # @param [String] id                If *nil*, assumes the current user.
  #
  # @return [Array<(ApiMyAccountSummary, ApiMyAccountPreferences)>]
  # @return [Array<(nil,nil)>] If there was a problem.
  #
  def fetch_my_account(id: nil)
    api  = ApiService.instance
    item = pref = error = nil
    if id && (item = api.get_account(user: id)).error?
      error = item.error_message
    elsif !id && (item = api.get_my_account).error?
      error = item.error_message
    elsif (pref = api.get_my_preferences).error?
      error = pref.error_message
    end
    if error
      flash.clear
      flash.now[:alert] = error
      item = pref = nil
    end
    return item, pref
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Initialize API service.
  #
  # @return [void]
  #
  def initialize_service
    @api = ApiService.update(user: current_user)
  end

  # ===========================================================================
  # :section: Testing
  # ===========================================================================

  public

  # To support API testing.
  #
  class ApiTesting

    BOOK         = '1933741'
    SERIES       = '46424'
    EDITION      = '2531073'
    READING_LIST = '325853'
    SUBSCRIPTION = READING_LIST # TODO: probably isn't right...
    FORMAT       = Api::FormatType.new.default
    LIMIT        = 5

    # Each method to be run in the trial along with a template of its arguments
    # to be updated via #trial_methods.
    #
    # @return [Hash{Symbol=>Hash}]
    #
    METHODS = {
      get_user_identity:            nil,
      get_my_account:               nil,
      get_account:                  { user: nil },
      get_my_preferences:           nil,
      get_my_assigned_titles:       { limit: nil },
      get_assigned_titles:          { user: nil, limit: nil },
      get_my_reading_lists:         {},
      get_reading_list_titles:      { readingListId: nil },
      get_my_download_history:      { limit: nil },
      get_subscriptions:            { user: nil },
      get_subscription:             { user: nil, subscriptionId: nil },
      get_user_agreements:          { user: nil },
      get_user_pod:                 { user: nil },
      get_organization_members:     {},
      get_title_count:              nil,
      get_titles:                   { limit: nil },
      get_title:                    { bookshareId: nil },
      download_title:               { bookshareId: nil, format: nil },
      get_periodicals:              { limit: nil },
      get_periodical:               { seriesId: nil },
      get_periodical_editions:      { seriesId: nil, limit: nil },
      download_periodical_edition:  { seriesId: nil, editionId: nil,
                                      format: nil },
      get_categories:               { limit: nil },
      get_catalog:                  { limit: nil },
      get_subscription_types:       nil,
    }.deep_freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # trial_methods
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def self.trial_methods(
      user:         ApiService::DEFAULT_USERNAME,
        book:         BOOK,
        series:       SERIES,
        edition:      EDITION,
        reading_list: READING_LIST,
        subscription: SUBSCRIPTION,
        format:       FORMAT,
        limit:        LIMIT
    )
      METHODS.transform_values do |args|
        args&.map { |k, v|
          case k
            when :bookshareId    then v = book
            when :editionId      then v = edition
            when :format         then v = format
            when :limit          then v = limit
            when :readingListId  then v = reading_list
            when :seriesId       then v = series
            when :subscriptionId then v = subscription
            when :user           then v = user
          end
          [k, v]
        }&.to_h
      end
    end

    # run_trials
    #
    # @param []
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def self.run_trials(methods = nil, user: nil, service: nil)
      service ||= ApiService.instance
      methods ||= trial_methods(user: user)
      methods.map { |method, args|
        value = service.send(method, args)
        error = value.is_a?(Api::Record::Base) && value.exception.present?
        param = args && args.to_s.tr('{}', '').gsub(/:(.+?)=>/, '\1: ')
        result = {
          value:      value,
          status:     (error ? 'error' : 'success'),
          endpoint:   service.last_endpoint,
          parameters: ("(#{param})" if param.present?),
        }
        [method, result]
      }.to_h
    end

  end

end

__loading_end(__FILE__)
