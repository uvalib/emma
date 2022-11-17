# app/services/bookshare_service/testing.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting "destructive testing".
#
module BookshareService::Testing

  include BookshareService::Common

  if BookshareService::DESTRUCTIVE_TESTING

    include Emma::Debug

    # =========================================================================
    # :section:
    # =========================================================================

    private

    FAULT_INJECTION   = true
    FORCED_EXCEPTION  = true

    # == Fault injection types

    bit = -1
    # noinspection RubyUnusedLocalVariable
    ALL_FAULTS = [
      BAD_CATEGORY      = 1 << (bit += 1),
      BAD_HISTORY       = 1 << (bit += 1),
      BAD_MEMBERS       = 1 << (bit += 1),
      BAD_MY_ACCOUNT    = 1 << (bit += 1),
      BAD_PREFERENCES   = 1 << (bit += 1),
      BAD_TITLE         = 1 << (bit += 1),
      BAD_USER_IDENTITY = 1 << (bit += 1),
    ].sum

    FAULT_METHOD = {
      #download_title:               BAD_TITLE,
      get_categories:               BAD_CATEGORY,
      get_my_account:               BAD_MY_ACCOUNT,
      get_my_download_history:      BAD_HISTORY,
      get_my_organization_members:  BAD_MEMBERS,
      get_my_preferences:           BAD_PREFERENCES,
      get_title:                    BAD_TITLE,
      #get_title_count:              BAD_TITLE,
      get_titles:                   BAD_TITLE,
      get_user_identity:            BAD_USER_IDENTITY,
    }.freeze

    # == Forced exception types

    DEFAULT_EXCEPTION = :response

    EXCEPTION_TYPE = {
      auth:           '(simulated) BS AUTHORIZATION ERROR',
      comm:           '(simulated) BS NETWORK COMMUNICATION ERROR',
      session:        '(simulated) BS NETWORK SESSION ERROR',
      connect:        '(simulated) BS NETWORK CONNECT ERROR',
      timeout:        '(simulated) BS NETWORK TIMEOUT ERROR',
      xmit:           '(simulated) BS NETWORK TRANSMIT ERROR',
      recv:           '(simulated) BS NETWORK RECEIVE ERROR',
      parse:          '(simulated) BS NETWORK PARSE ERROR',
      request:        '(simulated) BS BAD REQUEST',
      no_input:       '(simulated) BS MISSING REQUEST INPUT',
      response:       '(simulated) BS RESPONSE ERROR',
      empty_result:   '(simulated) BS EMPTY RESPONSE',
      html_result:    '(simulated) BS RESPONSE WITH HTML INSTEAD OF JSON',
      redirection:    '(simulated) BS REDIRECT ERROR',
      redirect_limit: '(simulated) BS "TOO MANY REDIRECTS"'
    }.freeze

    EXCEPTION_METHOD = {
      download_title:               DEFAULT_EXCEPTION,
      get_categories:               DEFAULT_EXCEPTION,
      get_my_account:               DEFAULT_EXCEPTION,
      get_my_download_history:      DEFAULT_EXCEPTION,
      get_my_organization_members:  DEFAULT_EXCEPTION,
      get_my_preferences:           DEFAULT_EXCEPTION,
      #get_title:                    :connect,
      get_title_count:              :timeout,
      #get_titles:                   :connect,
      get_user_identity:            :recv,
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

      # == Bad category
      if BAD_CATEGORY & faults
        tests += 1
        opt[:bad_param] = 'bad_category_param_value'
        opt[:limit]     = 'bad_category_limit'
        opt[:start]     = 'bad_category_start'
      end

      # == Bad account history
      if BAD_HISTORY & faults
        tests += 1
        opt[:bad_param] = 'bad_history_param_value'
        opt[:limit]     = 'bad_history_limit'
        opt[:sortOrder] = 'bad_history_sort'
        opt[:direction] = 'bad_history_direction'
      end

      # == Bad member list
      if BAD_MEMBERS & faults
        tests += 1
        opt[:bad_param] = 'bad_members_param_value'
        opt[:limit]     = 'bad_members_limit'
        opt[:sortOrder] = 'bad_members_sort'
        opt[:direction] = 'bad_members_direction'
      end

      # == Bad account summary
      if BAD_MY_ACCOUNT & faults
        tests += 1
        opt[:bad_param] = 'bad_myaccount_param_value'
      end

      # == Bad account preferences
      if BAD_PREFERENCES & faults
        tests += 1
        opt[:bad_param] = 'bad_preferences_param_value'
      end

      # == Bad title
      if BAD_TITLE & faults
        tests += 1
        opt[:bad_param] = 'bad_title_param_value'
        opt[:limit]     = 'bad_title_limit'
        opt[:start]     = 'bad_title_start'
      end

      # == Bad user identity
      if BAD_USER_IDENTITY & faults
        tests += 1
        opt[:bad_param] = 'bad_me_param_value'
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
      # noinspection RubyCaseWithoutElseBlockInspection, RubyNilAnalysis
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
