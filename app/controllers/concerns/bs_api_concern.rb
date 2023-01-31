# app/controllers/concerns/bs_api_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/bs_api" controller.
#
module BsApiConcern

  extend ActiveSupport::Concern

  include Emma::Json

  include BsApiHelper

  include ApiConcern
  include BookshareConcern

  # ===========================================================================
  # :section: Initialization
  # ===========================================================================

  if Log.info?
    extend Emma::TimeMethods
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

  # Invoke a Bookshare API method for display in the "Bookshare API Explorer".
  #
  # @param [Symbol] meth              One of ApiService#HTTP_METHODS.
  # @param [String] path
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Hash{Symbol=>Any}]
  #
  def bs_api_explorer(meth, path, **opt)
    meth = meth&.downcase&.to_sym || :get
    data = bs_api.api(meth, path, **opt.merge(no_raise: true))&.body&.presence
    {
      method:    meth.to_s.upcase,
      path:      path,
      opt:       opt.presence || '',
      url:       bs_api_explorer_url(path, **opt),
      result:    data&.force_encoding('UTF-8'),
      exception: api_exception,
    }.compact
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
      resourceId:     '???',                              # TODO: ???
      readingListId:  '325853',
      subscriptionId: '???',                              # TODO: ???
      messageId:      '???',                              # TODO: ???
      popularListId:  'bW9zdFBvcHVsYXI6RU1NQTo3MjA6MzM=',
      organization:   'emma',                             # TODO: ???
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
      methods.map { |meth, opts|
        begin
          value = service.send(meth, **opts)
          error = value ? value.try(:exception) : "#{meth.inspect} failed"
        rescue => e
          value = nil
          error = e
        end
        path  = value && service.latest_endpoint
        param = path  && opts.to_s.remove(/[{}]/).presence
        param&.gsub!(/:(.+?)=>/, '\1: ')
        trial = {
          endpoint:   path,
          parameters: (param && "(#{param})"),
          status:     (error ? 'error' : 'success'),
          value:      value,
          error:      error
        }.compact
        [meth, trial]
      }.to_h
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
