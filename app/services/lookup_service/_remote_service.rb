# app/services/lookup_service/_remote_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Abstract base class for remote bibliographic metadata search services.
#
class LookupService::RemoteService < ApiService

  include Emma::Json

  # Include send/receive modules from "lookup_service/_remote_service/**.rb".
  include_submodules(self)

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include LookupService::RemoteService::Properties
    include LookupService::RemoteService::Common
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [LookupService::Request]
  attr_reader :request

  # @return [LookupService::Response, nil]
  attr_reader :result

  # @return [Float, nil]
  attr_reader :start_time

  # @return [Float, nil]
  attr_reader :end_time

  # @return [Boolean]
  attr_reader :enabled

  alias :enabled? :enabled

  # Initialize a new remote service instance.
  #
  # @param [Hash] opt
  #
  # @option opt [String]        :base_url   Def.: BASE_URL defined by subclass.
  # @option opt [String]        :api_key    Def.: API_KEY defined by subclass.
  # @option opt [Array<Symbol>] :types      Def.: TYPES defined by subclass.
  # @option opt [Integer]       :priority   Def.: PRIORITY defined by subclass.
  # @option opt [Float]         :timeout    Def.: TIMEOUT defined by subclass.
  # @option opt [Boolean]       :enabled    Def.: from configuration.
  #
  def initialize(**opt)
    super
  end

  # ===========================================================================
  # :section: LookupService::RemoteService::Properties overrides
  # ===========================================================================

  public

  # Types of identifiers that the external service can find.
  #
  # @return [Array<Symbol>]
  #
  def types
    options[:types] || super
  end

  # How important the external service is as an authority for the type(s) of
  # identifiers it can search.
  #
  # @type [Integer]
  #
  def priority
    options[:priority] || super
  end

  # How long to wait for a response from the external service.
  #
  # @return [Float]
  #
  def timeout
    options[:timeout] || super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the request sequence has begun.
  #
  def started?
    !start_time.nil?
  end

  # Indicate whether the request sequence has finished.
  #
  def finished?
    !end_time.nil?
  end

  # How long the total request sequence took.
  #
  # @param [Integer] precision        Digits after the decimal point.
  #
  # @return [Float] Wall clock time in seconds; zero if not finished.
  #
  def duration(precision: 2)
    return 0.0 unless finished?
    # noinspection RubyMismatchedArgumentType
    (end_time - start_time).round(precision).to_f
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the request has been sent and a response received.
  #
  def request_sent?
    !response.nil?
  end

  # Indicate whether the external service reported a successful request.
  #
  def succeeded?
    # noinspection RubyNilAnalysis
    request_sent? && response.success?
  end

  # Indicate whether the request was not successful.
  #
  def failed?
    # noinspection RubyNilAnalysis
    request_sent? && !response.success?
  end

  # Indicate whether the request has been sent but a response has not yet
  # been received.
  #
  def in_progress?
    started? && response.nil?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Receive a request to lookup items on the remote service.
  #
  # @param [LookupService::Request, Hash, Array, String] items
  # @param [Boolean] extended         If *true*, include :diagnostic.
  #
  # @return [LookupService::Response] The value assigned to @result.
  #
  def lookup_metadata(items, extended: false, **)
    @request    = pre_flight(items)
    @start_time = timestamp
    result_data = fetch(@request)
    @end_time   = timestamp
    @result     = post_flight(result_data, extended: extended)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Marshal data in preparation for the remote request.
  #
  # @param [LookupService::Request, Hash, Array, String] items
  #
  # @return [LookupService::Request]   The value for @request.
  #
  def pre_flight(items)
    LookupService::Request.wrap(items)
  end

  # Send the request to the remove service.
  #
  # @param [LookupService::Request] req  Def.: `@request`.
  #
  # @return [Api::Message]
  # @return [nil]                     If no request was made.
  #
  def fetch(req = self.request)
    not_implemented 'to be overridden by the subclass'
  end

  # Extract results from the remote response.
  #
  # @param [Api::Message, LookupService::Data, Hash, nil] obj
  # @param [Boolean] extended         If *true*, include :diagnostic.
  #
  # @return [LookupService::Response] The value for @result.
  #
  def post_flight(obj, extended: false)
    data = transform(obj, extended: extended)
    LookupService::Response.new.tap do |resp|
      resp[:service]    = service_name
      resp[:duration]   = duration
      resp[:status]     = data ? 'completed' : 'failed'
      resp[:count]      = data.item_count             if data
      resp[:data]       = { items: data.item_values } if data
      resp[:diagnostic] = data.diagnostic             if data && extended
    end
  end

  # Overridden by the subclass to transform response message data into
  # normalized data which is passed to this superclass method.
  #
  # @param [Api::Message, LookupService::Data, Hash, nil] msg
  # @param [Boolean] extended         If *true*, include :diagnostic.
  #
  # @return [LookupService::Data]
  # @return [nil]                     If *msg* is *nil*.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def transform(msg, extended: false)
    return if msg.nil?
    case msg
      when Api::Message
        recs = msg.api_records
        data = {}
        data[:items]      = transform_multiple(recs) if recs.present?
        data[:diagnostic] = msg.field_hierarchy      if extended
      when LookupService::Data
        data = msg
      else
        data = json_parse(msg)
    end
    if data.nil?
      Log.warn("#{self.class}.#{__method__}: #{msg.class}: unexpected")
    elsif extended && (!data.is_a?(Hash) || !data[:diagnostic].is_a?(Hash))
      Log.warn("#{self.class}.#{__method__}: msg[:diagnostic] missing")
    end
    LookupService::Data.wrap(data)
  end

  # transform_multiple
  #
  # @param [Array<Api::Record>] recs
  #
  # @return [Hash{String=>Array<Hash>}]
  #
  def transform_multiple(recs)
    recs.reduce({}) do |result, rec|
      key   = rec.best_identifier
      value = transform_single(rec)
      (key && value) ? result.merge!(key => [*result[key], value]) : result
    end
  end

  # Convert a single service-specific item record into values that can be used
  #
  # @param [Api::Record] rec
  # @param [Hash]        values
  #
  # @return [Hash]
  # @return [nil]                     If the record should be ignored.
  #
  def transform_single(rec, **values)
    LookupService::Data::Item::TEMPLATE.merge(values).tap { |result|
      result[:dc_title]              ||= rec.full_title
      result[:dc_creator]            ||= rec.creator_list
      result[:dc_identifier]         ||= rec.identifier_list
      result[:dc_subject]            ||= rec.subject_list
      result[:dc_language]           ||= rec.language_list
      result[:dc_publisher]          ||= rec.full_publisher
      result[:dc_description]        ||= rec.description_list
      result[:bib_series]            ||= rec.journal_title
      result[:bib_seriesType]        ||= rec.series_type
      result[:bib_seriesPosition]    ||= rec.series_position
      result[:emma_publicationDate]  ||= rec.publication_date
      result[:dcterms_dateCopyright] ||= rec.publication_year
    }.compact_blank!
  end

end

__loading_end(__FILE__)
