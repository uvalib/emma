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
      when Faraday::Error
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

    include Api
    include Api::Common

    include GenericHelper

    # Fixed parameter values to use when generating results for the Bookshare
    # API Explorer.
    #
    # @type [Hash{Symbol=>*}]
    #
    TRIAL_VALUES = {
      bookshareId:    '1933741',
      seriesId:       '46424',
      editionId:      '2531073',
      resourceId:     '???',      # TODO: ???
      readingListId:  '325853',
      subscriptionId: '???',      # TODO: ???
      organization:   'emma',     # TODO: ???
      format:         FormatType.default,
      limit:          5,
    }.deep_freeze

    # Group #TRIAL_METHODS by topic in this order.
    #
    # @type [Array<String,Regexp>]
    #
    TRIAL_TOPICS = (
      %w(
        UserAccount
        MembershipUserAccounts
        ActiveTitles
        MembershipActiveTitles
        AssignedTitles
        ReadingLists
        Titles
        Periodicals
      ) << /Organization/
    ).freeze

    # Each method to be run in the trial.
    #
    # @type [Array<Symbol>]
    #
    TRIAL_METHODS =
      ApiService.api_methods
        .select  { |method, _| method.to_s.start_with?('get_', 'download_') }
        .sort_by { |method, properties|
          topic = properties[:topic]
          topic = 'ReadingLists' if method.match?('reading_list')
          order =
            TRIAL_TOPICS.index { |t| topic.match?(t) } || TRIAL_TOPICS.size
          name  = method.to_s
          name  = "z#{name}" if name.include?('download')
          [order, name]
        }.to_h.keys

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Supply parameters for #TRIAL_METHODS from #TRIAL_VALUES.
    #
    # @param [Hash] opt
    #
    # @option opt [String]     bookshareId
    # @option opt [String]     editionId
    # @option opt [String]     format
    # @option opt [Integer]    limit
    # @option opt [String]     organization
    # @option opt [String]     readingListId
    # @option opt [String]     resourceId
    # @option opt [String]     seriesId
    # @option opt [String]     subscription
    # @option opt [User]       user
    # @option opt [ApiService] service
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def self.trial_methods(**opt)
      opt, param_value = partition_options(opt, :user, :service)
      service = opt[:service]
      user    = opt[:user]&.to_s || service&.user&.to_s
      service ||= ApiService.new(user: opt[:user], no_raise: true)
      param_value.reverse_merge!(TRIAL_VALUES)
      param_value[:user] = user if user.present?
      TRIAL_METHODS.map do |method|
        np = service.named_parameters(method, no_alias: true)
        rp = service.required_parameters(method)
        op = service.optional_parameters(method)
        parameters =
          (np + rp + op).map { |k|
            v = param_value[k]
            [k, v] unless v.nil?
          }.compact.to_h
        [method, parameters]
      end
    end

    # run_trials
    #
    # @param [Hash{Symbol=>Hash}, nil] methods  Default: `#trial_methods`.
    # @param [User, nil]               user
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def self.run_trials(methods = nil, user: nil)
      service = ApiService.new(user: user, no_raise: true)
      methods ||= trial_methods(user: user, service: service)
      methods.map { |method, opts|
        param = opts.to_s.tr('{}', '').gsub(/:(.+?)=>/, '\1: ')
        value = service.send(method, **opts)
        error = (value.exception if value.is_a?(Api::Record::Base))
        trial = {
          endpoint:   service.latest_endpoint,
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
