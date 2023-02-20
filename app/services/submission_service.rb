# app/services/submission_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Batch submission service.
#
class SubmissionService < ApiService

  include Emma::Json

  include SubmissionService::Properties
  include SubmissionService::Action
  include SubmissionService::Common
  include SubmissionService::Definition
  include SubmissionService::Status

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new remote service instance.
  #
  # @param [Hash] opt
  #
  # @option opt [Integer]       :priority   Def.: PRIORITY defined by subclass.
  # @option opt [Float]         :timeout    Def.: TIMEOUT defined by subclass.
  #
  def initialize(**opt)
    super
  end

  # ===========================================================================
  # :section: SubmissionService::Properties overrides
  # ===========================================================================

  public

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

  # Indicate whether the request has been sent and a response received.
  #
  def request_sent?
    !response.nil?
  end

  # Indicate whether the external service reported a successful request.
  #
  def succeeded?
    request_sent? && response.success?
  end

  # Indicate whether the request was not successful.
  #
  def failed?
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

  # Receive a request to start batch creation of EMMA entries.
  #
  # @param [SubmissionService::Request, Symbol, nil] request
  # @param [Symbol, nil]                             meth
  # @param [Manifest, String, nil]                   manifest
  # @param [Hash]                                    opt
  #
  # @option opt [SubmitChannel] :channel
  #
  # @return [Array<SubmissionService::Response>]
  # @return [Array<Hash>]
  # @return [Array<SubmitJob,nil>]
  # @return [SubmissionService::Response]
  # @return [Hash]
  # @return [SubmitJob, nil]
  #
  def make_request(request = nil, meth: nil, manifest: nil, **opt)
    request, meth = [nil, request] if request.is_a?(Symbol)
    request ||= pre_flight(meth, manifest, **opt)
    # noinspection RubyMismatchedArgumentType
    SubmissionService.make_request(request, **opt, service: self)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  REQUEST_OPTIONS = %i[service batch slice no_job no_async].freeze

  # Process submitted items.
  #
  # @param [SubmissionService::Request] request
  # @param [SubmitChannel, nil]         channel
  # @param [SubmissionService, nil]     service     Service instance
  # @param [User, String, nil]          user        Def.: service.user
  # @param [Boolean]                    no_job
  # @param [Boolean]                    no_async
  # @param [Hash]                       opt
  #
  # @option opt [Integer, Boolean, nil] :batch        Def.: #DEF_BATCH
  # @option opt [Integer, Boolean, nil] :slice        Def.: #DEF_SLICE
  # @option opt [Numeric, Boolean, nil] :timeout      Def.: #DEFAULT_TIMEOUT
  # @option opt [Boolean]               :simulation   Def.: #SIMULATION_ONLY
  #
  # @return [Array<SubmissionService::Response>]
  # @return [Array<Hash>]
  # @return [Array<SubmitJob,nil>]
  # @return [SubmissionService::Response]
  # @return [Hash]
  # @return [SubmitJob, nil]
  #
  def self.make_request(
    request,
    channel:  nil,
    service:  nil,
    user:     nil,
    no_job:   false,
    no_async: false,
    **opt
  )
    opt[:service]     = service ||= new(**opt)
    opt[:user]        = (user || service.user).to_s
    opt[:batch]       = batch_option(opt[:batch])
    opt[:slice]       = slice_option(opt[:slice])
    opt[:timeout]     = timeout_option(opt[:timeout])
    opt[:no_job]      = no_job
    opt[:no_async]    = no_async ||= channel.nil?
    opt[:stream_name] = channel&.send(:stream_name)
    opt[:simulation]  = true if SIMULATION_ONLY && !opt.key?(:simulation)
    opt.compact!
    request = pre_flight(request, **opt)
    # noinspection RubyMismatchedArgumentType
    case
      when no_job   then process(request, **opt)
      when no_async then schedule_sync(request, **opt)
      else               schedule_async(request, **opt)
    end
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # Perform operation asynchronously.
  #
  # @param [SubmissionService::Request] request
  # @param [Hash]                       opt     Passed to SubmitJob#perform
  #
  # @option opt [Numeric, nil] :timeout
  #
  # @return [SubmitJob, nil]
  #
  def self.schedule_async(request, **opt)
    # noinspection RubyMismatchedReturnType
    SubmitJob.perform_later(request, **opt) || nil
  end

  # Perform operation immediately.
  #
  # @param [SubmissionService::Request] request
  # @param [Hash]                       opt     Passed to SubmitJob#perform.
  #
  # @return [Hash]
  #
  def self.schedule_sync(request, **opt)
    SubmitJob.perform_now(request, **opt)
  end

  # Perform operation immediately without passing through job control logic.
  #
  # @param [SubmissionService::Request] request
  # @param [SubmissionService]          service
  # @param [Hash]                       opt
  #
  # @return [SubmissionService::Response]
  # @return [Array<SubmissionService::Response>]
  # @return [Array<Hash>]
  # @return [Array<SubmitJob,nil>]
  #
  def self.process(request, service:, **opt)
    service.process(request, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Called to directly perform an operation.
  #
  # @param [SubmissionService::Request] request
  # @param [Hash]                       opt
  #
  # @return [SubmissionService::Response]
  # @return [Array<SubmissionService::Response>]
  # @return [Array<Hash>]
  # @return [Array<SubmitJob,nil>]
  #
  def process(request, **opt)
    opt[:service] ||= self
    # noinspection RubyMismatchedArgumentType
    if request.is_a?(SubmissionService::BatchSubmitRequest)
      process_batch(request, **opt)
    else
      process_all(request, **opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # process_batch
  #
  # @param [SubmissionService::BatchSubmitRequest] request
  # @param [Hash]                                  opt
  #
  # @return [Array<SubmissionService::SubmitResponse>]
  # @return [Array<Hash>]
  # @return [Array<SubmitJob,nil>]
  #
  def process_batch(request, **opt)
    requests = request.requests
    # noinspection RubyMismatchedReturnType
    case
      when opt[:no_job]   then requests.map { |r| process_all(r, **opt) }
      when opt[:no_async] then requests.map { |r| schedule_sync(r, **opt) }
      else                     requests.map { |r| schedule_async(r, **opt) }
    end
  end

  # process_all
  #
  # @param [SubmissionService::Request] request
  # @param [Hash]                       opt
  #
  # @return [SubmissionService::Response]
  #
  def process_all(request, **opt)
    meth = request&.request_method&.presence or
      raise "#{self_class}: #{__method__}: no method for #{request.inspect}"
    send(meth, request, **opt)
  end

  delegate :schedule_sync, :schedule_async, to: :class

end

__loading_end(__FILE__)
