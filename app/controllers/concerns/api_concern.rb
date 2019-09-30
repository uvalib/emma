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

  protected

  # Attempt to interpret *arg* as JSON if it is a string.
  #
  # @param [String, Object] arg
  # @param [*]              default   On parse failure, return this if provided
  #                                     (or return *arg* otherwise).
  #
  # @return [Hash, Object]
  #
  def try_json_parse(arg, default: :original)
    arg.is_a?(String) &&
      (MultiJson.load(arg) rescue nil) ||
      ((default == :original) ? arg : default)
  end

  # Attempt to interpret *arg* as an exception or a record with an exception.
  #
  # @param [Api::Record::Base, Exception, Object] arg
  # @param [*]              default   On parse failure, return this if provided
  #                                     (or return *arg* otherwise).
  #
  # @return [Hash, String, Object]
  #
  def try_exception_parse(arg, default: :original)
    case (ex = arg.respond_to?(:exception) && arg.exception)
      when Faraday::ClientError
        {
          message:   ex.message,
          response:  ex.response,
          exception: ex.wrapped_exception
        }.reject { |_, v| v.blank? }
      when Exception
        ex.message
      else
        (default == :original) ? arg : default
    end
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
    FORMAT       = FormatType.new.default
    LIMIT        = 5

    # Each method to be run in the trial along with a template of its arguments
    # to be updated via #trial_methods.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    METHODS = {
      get_user_identity:            nil,
      get_my_account:               nil,
      get_account:                  { user: nil },
      get_my_preferences:           nil,
      get_my_assigned_titles:       { limit: nil },
      get_assigned_titles:          { user: nil, limit: nil },
      get_my_reading_lists:         {},
      get_reading_lists:            {},
      get_reading_list_titles:      { readingListId: nil },
      get_my_download_history:      { limit: nil },
      get_subscriptions:            { user: nil },
      get_subscription:             { user: nil, subscriptionId: nil },
      get_user_agreements:          { user: nil },
      get_user_pod:                 { user: nil },
      get_my_organization_members:  {},
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
    # @param [String]  user
    # @param [String]  book
    # @param [String]  series
    # @param [String]  edition
    # @param [String]  reading_list
    # @param [String]  subscription
    # @param [String]  format
    # @param [Integer] limit
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def self.trial_methods(
      user:         ApiService::DEFAULT_USER,
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
          # noinspection RubyCaseWithoutElseBlockInspection
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
    # @param [Hash{Symbol=>Hash}, nil] methods  Default: `#trial_methods`.
    # @param [String]                  user
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def self.run_trials(methods = nil, user: nil, service: nil)
      service ||= ApiService.instance
      methods ||= user ? trial_methods(user: user) : trial_methods
      methods.map { |method, args|
        value = service.send(method, args)
        error = (value.exception if value.is_a?(Api::Record::Base))
        param = args && args.to_s.tr('{}', '').gsub(/:(.+?)=>/, '\1: ')
        trial = {
          endpoint:   service.last_endpoint,
          parameters: ("(#{param})" if param.present?),
          status:     (error ? 'error' : 'success'),
          value:      value,
          error:      error
        }.reject { |_, v| v.nil? }
        [method, trial]
      }.to_h
    end

  end

end

__loading_end(__FILE__)
