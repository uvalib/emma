# app/services/aws_s3_service/testing.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting "destructive testing".
#
module AwsS3Service::Testing

  include AwsS3Service::Common

  if AwsS3Service::DESTRUCTIVE_TESTING

    include Emma::Debug

    # =========================================================================
    # :section:
    # =========================================================================

    private

    FAULT_INJECTION   = true
    FORCED_EXCEPTION  = true

    # === Fault injection types

    bit = -1
    # noinspection RubyUnusedLocalVariable, RubyMismatchedConstantType
    ALL_FAULTS = [
      BAD_REPO     = 1 << (bit += 1),
      BAD_FILE     = 1 << (bit += 1),
      BAD_FILE_KEY = 1 << (bit += 1),
      BAD_KEY      = 1 << (bit += 1),
    ].sum

    FAULT_METHOD = {
      #creation_request:     BAD_REPO | BAD_FILE | BAD_FILE_KEY | BAD_KEY,
      modification_request: BAD_REPO | BAD_FILE | BAD_FILE_KEY | BAD_KEY,
      removal_request:      BAD_REPO,
      dequeue:              BAD_REPO,
    }.freeze

    # === Forced exception types

    DEFAULT_EXCEPTION = :response

    EXCEPTION_TYPE = {
      auth:           '(simulated) AWS S3 AUTHORIZATION ERROR',
      comm:           '(simulated) AWS S3 NETWORK COMMUNICATION ERROR',
      session:        '(simulated) AWS S3 NETWORK SESSION ERROR',
      connect:        '(simulated) AWS S3 NETWORK CONNECT ERROR',
      timeout:        '(simulated) AWS S3 NETWORK TIMEOUT ERROR',
      xmit:           '(simulated) AWS S3 NETWORK TRANSMIT ERROR',
      recv:           '(simulated) AWS S3 NETWORK RECEIVE ERROR',
      parse:          '(simulated) AWS S3 NETWORK PARSE ERROR',
      request:        '(simulated) AWS S3 BAD REQUEST',
      no_input:       '(simulated) AWS S3 MISSING REQUEST INPUT',
      response:       '(simulated) AWS S3 RESPONSE ERROR',
      empty_result:   '(simulated) AWS S3 EMPTY RESPONSE',
      html_result:    '(simulated) AWS S3 RESPONSE WITH HTML INSTEAD OF JSON',
      redirection:    '(simulated) AWS S3 REDIRECT ERROR',
      redirect_limit: '(simulated) AWS S3 "TOO MANY REDIRECTS"'
    }.freeze

    EXCEPTION_METHOD = {
      creation_request:     DEFAULT_EXCEPTION,
      #modification_request: DEFAULT_EXCEPTION,
      #removal_request:      DEFAULT_EXCEPTION,
      #dequeue:              DEFAULT_EXCEPTION,
    }.freeze

    # =========================================================================
    # :section: ApiService::Common overrides
    # =========================================================================

    public

    # Inject faults (if defined) prior to invoking the API.
    #
    # @param [Symbol] operation
    # @param [Array<AwsS3::Message::SubmissionRequest,Model,Hash,String>] items
    # @param [Hash]   opt
    #
    def api(operation, *items, **opt)
      meth = opt[:meth] || operation || calling_method&.to_sym
      inject_exception(meth) and return
      inject_fault!(meth, items)
      super
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Injection point for "destructive testing" modifications to message data.
    #
    # @param [Symbol, nil]                             meth  API service method
    # @param [AwsS3::Message::SubmissionRequest,Array] item  Target record(s).
    #
    # @return [Integer]               Test cases applied.
    # @return [nil]                   If no injection was performed
    #
    def inject_fault!(meth, item)
      return unless FAULT_INJECTION
      return item.each { |i| send(__method__, meth, i) } if item.is_a?(Array)
      return unless (faults = meth ? FAULT_METHOD[meth] : ALL_FAULTS).present?
      unless item.is_a?(AwsS3::Message::SubmissionRequest)
        Log.warn do
          "#{__method__}: expected SubmissionRequest; got #{item.inspect}"
        end unless item.nil?
        return
      end

      __debug_banner("#{meth} #{item.submission_id} FAULT")
      tests = 0

      # === Bad bucket specifier
      if BAD_REPO & faults
        tests += 1
        item.emma_repository = 'bad repo'
      end

      # === Bad file
      if BAD_FILE & faults
        tests += 1
        item.instance_variable_set(:@file, nil)
      end

      # === Bad file key
      if BAD_FILE_KEY & faults
        tests += 1
        item.instance_variable_set(:@file_key, nil)
      end

      # === Bad package key
      if BAD_KEY & faults
        tests += 1
        item.instance_variable_set(:@key, nil)
      end

      positive(tests)
    end

    # Injection point for "destructive testing" simulation of exception.
    # If an exception is not specified, the calling method must be included
    # in #EXCEPTION_METHOD.
    #
    # @param [Symbol, nil] meth     Calling method.
    # @param [Class<ApiService::Error>,ApiService::Error,Symbol,String,nil] ex
    # @param [Array]       args     Passed to initializer if *ex* is a class.
    #
    # @return [ApiService::Error, nil]
    #
    def inject_exception(meth, ex = nil, *args)
      return unless FORCED_EXCEPTION
      return unless (de = meth ? EXCEPTION_METHOD[meth] : DEFAULT_EXCEPTION)
      case (ex ||= de)
        when Class  then ex = ex.new(*args)
        when String then ex = error_classes[de].new(ex, *args)
        when Symbol then ex = error_classes[ex].new(EXCEPTION_TYPE[ex], *args)
      end
      return unless ex.present?
      __debug_banner("#{self.class}.#{meth} #{ex.class}")
      # noinspection RubyMismatchedArgumentType
      set_error(ex)
    end

  else

    protected

    neutralize(:inject_fault!)
    neutralize(:inject_exception)

  end

end

__loading_end(__FILE__)
