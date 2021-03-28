# app/controllers/concerns/api_explorer_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/api" controller.
#
module ApiExplorerConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'ApiExplorerConcern')
  end

  include Emma::Json
  include ExplorerHelper

  # ===========================================================================
  # :section: Initialization
  # ===========================================================================

  if Log.info?
    extend Emma::Time
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

  # Attempt to interpret *arg* as an exception or a record with an exception.
  #
  # @param [Bs::Api::Record, Exception, Object] arg
  # @param [*] default                On parse failure, return this if provided
  #                                     (or return *arg* otherwise).
  #
  # @return [Hash, String, Object]
  #
  def safe_exception_parse(arg, default: :original)
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

    include Emma::Common

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Fixed parameter values to use when generating results for the Bookshare
    # API Explorer.
    #
    # @type [Hash{Symbol=>String,Integer}]
    #
    VALUES = {
      bookshareId:    '1933741',
      seriesId:       '46424',
      editionId:      '2531073',
      resourceId:     '???',      # TODO: ???
      readingListId:  '325853',
      subscriptionId: '???',      # TODO: ???
      messageId:      '???',      # TODO: ???
      organization:   'emma',     # TODO: ???
      format:         BsFormatType.default,
      limit:          5,
    }.deep_freeze

    # Group #METHODS by topic in this order.
    #
    # @type [Array<String,Regexp>]
    #
    TOPICS = [
      'UserAccount',
      'MembershipUserAccounts',
      'ActiveTitles',
      'MembershipActiveTitles',
      'AssignedTitles',
      'ReadingLists',
      'Titles',
      'Periodicals',
      /Message/,
      /Organization/
    ].freeze

    # Each method to be run in the trial.
    #
    # @type [Array<Symbol>]
    #
    #--
    # noinspection RubyNilAnalysis
    #++
    METHODS =
      BookshareService.api_methods
        .select  { |method, _| method.to_s.start_with?('get_', 'download_') }
        .sort_by { |method, properties|
          name  = method.to_s
          name  = "z#{name}" if name.include?('download')
          topic = properties[:topic]
          topic = 'ReadingLists' if name.match?('reading_list')
          order =
            TOPICS.index { |t|
              t.is_a?(Regexp) ? (topic =~ t) : (topic == t)
            } || TOPICS.size
          [order, name]
        }.to_h.keys

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Supply parameters for #METHODS from #VALUES.
    #
    # @param [BookshareService] service
    # @param [Hash]             opt
    #
    # @option opt [String]  :bookshareId
    # @option opt [String]  :editionId
    # @option opt [String]  :format
    # @option opt [Integer] :limit
    # @option opt [String]  :organization
    # @option opt [String]  :readingListId
    # @option opt [String]  :resourceId
    # @option opt [String]  :seriesId
    # @option opt [String]  :subscription
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def self.trial_methods(service:, **opt)
      param_value = VALUES.merge(opt)
      param_value[:user] = service.user.to_s if service.user.present?
      METHODS.map { |meth|
        np = service.named_parameters(meth, no_alias: true)
        rp = service.required_parameters(meth)
        op = service.optional_parameters(meth)
        parameters =
          (np + rp + op).map { |k|
            v = param_value[k]
            [k, v] unless v.nil?
          }.compact.to_h
        [meth, parameters]
      }.to_h
    end

    # run_trials
    #
    # @param [User, nil]               user
    # @param [Hash{Symbol=>Hash}, nil] methods  Default: `#trial_methods`.
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def self.run_trials(user: nil, methods: nil)
      service = BookshareService.new(user: user, no_raise: true)
      methods = trial_methods(service: service) if methods.blank?
      # noinspection RubyNilAnalysis
      methods.map { |meth, opts|
        param = opts.to_s.remove(/[{}]/).gsub(/:(.+?)=>/, '\1: ')
        value = service.send(meth, **opts) rescue nil
        error =
          if value.nil?
            "missing method - #{meth.inspect}"
          elsif value.respond_to?(:exception)
            value.exception
          end
        trial = {
          endpoint:   service.latest_endpoint,
          parameters: ("(#{param})" if param.present?),
          status:     (error ? 'error' : 'success'),
          value:      value,
          error:      error
        }.compact
        [meth, trial]
      }.to_h
    end

  end

end

__loading_end(__FILE__)
