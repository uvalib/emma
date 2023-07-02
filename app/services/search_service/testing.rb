# app/services/search_service/testing.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting "destructive testing".
#
module SearchService::Testing

  include SearchService::Common

  if SearchService::DESTRUCTIVE_TESTING

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
      BAD_PARAM   = 1 << (bit += 1),
      BAD_REPO    = 1 << (bit += 1),
      BAD_FORMAT  = 1 << (bit += 1),
      PDF_DATES   = 1 << (bit += 1),
    ].sum

    FAULT_METHOD = {
      get_records:  BAD_PARAM | BAD_FORMAT,
      get_record:   nil, #BAD_PARAM | BAD_FORMAT,
    }.freeze

    # === Forced exception types

    DEFAULT_EXCEPTION = :response

    EXCEPTION_TYPE = {
      auth:           '(simulated) SEARCH AUTHORIZATION ERROR',
      comm:           '(simulated) SEARCH NETWORK COMMUNICATION ERROR',
      session:        '(simulated) SEARCH NETWORK SESSION ERROR',
      connect:        '(simulated) SEARCH NETWORK CONNECT ERROR',
      timeout:        '(simulated) SEARCH NETWORK TIMEOUT ERROR',
      xmit:           '(simulated) SEARCH NETWORK TRANSMIT ERROR',
      recv:           '(simulated) SEARCH NETWORK RECEIVE ERROR',
      parse:          '(simulated) SEARCH NETWORK PARSE ERROR',
      request:        '(simulated) SEARCH BAD REQUEST',
      no_input:       '(simulated) SEARCH MISSING REQUEST INPUT',
      response:       '(simulated) SEARCH RESPONSE ERROR',
      empty_result:   '(simulated) SEARCH EMPTY RESPONSE',
      html_result:    '(simulated) SEARCH RESPONSE WITH HTML INSTEAD OF JSON',
      redirection:    '(simulated) SEARCH REDIRECT ERROR',
      redirect_limit: '(simulated) SEARCH "TOO MANY REDIRECTS"'
    }.freeze

    EXCEPTION_METHOD = {
      get_records:  DEFAULT_EXCEPTION,
      get_record:   nil,
    }.freeze

    # =========================================================================
    # :section: ApiService::Common overrides
    # =========================================================================

    public

    # Inject faults (if defined) prior to invoking the API.
    #
    # @param [Symbol, String]           verb
    # @param [Array<String,ScalarType>] args
    # @param [Hash]                     opt
    #
    def api(verb, *args, **opt)
      meth = opt[:meth] || calling_method&.to_sym
      inject_exception(meth) and return
      inject_fault!(meth, opt)
      super
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Injection point for "destructive testing" modifications to message data.
    #
    # @param [Symbol, nil] meth       API service method.
    # @param [Hash]        opt        API request parameters to be altered.
    #
    # @return [Integer]               Test cases applied.
    # @return [nil]                   If no injection was performed
    #
    def inject_fault!(meth, opt)
      return unless FAULT_INJECTION
      return unless (faults = meth ? FAULT_METHOD[meth] : ALL_FAULTS).present?
      unless opt.is_a?(Hash)
        Log.warn do
          "#{__method__}: expected Hash; got #{opt.inspect}"
        end unless opt.nil?
        return
      end

      __debug_banner("#{self.class}.#{meth} FAULT")
      tests = 0

      # === Bogus parameters (should be ignored)
      # noinspection SpellCheckingInspection
      if BAD_PARAM & faults
        tests += 1
        opt[:bad]      = 'bad_param'
        opt[:"sq'bad"] = 'bad_param_with_single_quote'
        opt[:'dq"bad'] = 'bad_param_with_double_quote'
      end

      # === Bad repository
      if BAD_REPO & faults
        tests += 1
        opt[:repository] = 'bad_repo'
      end

      # === Bad format
      if BAD_FORMAT & faults
        tests += 1
        opt[:format] = 'bad_format'
        #opt[:format] = '.bad_format+w/punct,'
        #opt[:format] = 'bad_format"with_double_quote'
        #opt[:format] = "bad_format'with_single_quote"
      end

      # === PDF-style dates.
      if PDF_DATES & faults
        tests += 1
        opt[:lastRemediationDate] = "D:20210327195230+05'00'"
      end

      encode_parameters!(opt)

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
