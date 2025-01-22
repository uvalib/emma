# app/services/ingest_service/testing.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting "destructive testing".
#
module IngestService::Testing

  include IngestService::Common

  if IngestService::DESTRUCTIVE_TESTING

    include Emma::Debug

    # =========================================================================
    # :section:
    # =========================================================================

    private

    FAULT_INJECTION   = true
    FORCED_EXCEPTION  = true

    # === Fault injection types

    bit = -1
    # noinspection RubyUnusedLocalVariable
    ALL_FAULTS = [
      SINGLETON_FIELDS_BAD  = 1 << (bit += 1),
      STRING_FIELDS_BAD     = 1 << (bit += 1),
      ARRAY_FIELDS_BAD      = 1 << (bit += 1),
      DATE_FIELDS_BAD       = 1 << (bit += 1),
      PDF_DATES             = 1 << (bit += 1),
      ALL_FIELDS_BAD        = 1 << (bit += 1),
    ].sum

    FAULT_METHOD = {
      put_records:    ALL_FIELDS_BAD,
      delete_records: nil,
      get_records:    nil,
    }.freeze

    # === Forced exception types

    DEFAULT_EXCEPTION = :response

    EXCEPTION_TYPE = {
      auth:           '(simulated) INGEST AUTHORIZATION ERROR',
      comm:           '(simulated) INGEST NETWORK COMMUNICATION ERROR',
      session:        '(simulated) INGEST NETWORK SESSION ERROR',
      connect:        '(simulated) INGEST NETWORK CONNECT ERROR',
      timeout:        '(simulated) INGEST NETWORK TIMEOUT ERROR',
      xmit:           '(simulated) INGEST NETWORK TRANSMIT ERROR',
      recv:           '(simulated) INGEST NETWORK RECEIVE ERROR',
      parse:          '(simulated) INGEST NETWORK PARSE ERROR',
      request:        '(simulated) INGEST BAD REQUEST',
      no_input:       '(simulated) INGEST MISSING REQUEST INPUT',
      response:       '(simulated) INGEST RESPONSE ERROR',
      empty_result:   '(simulated) INGEST EMPTY RESPONSE',
      html_result:    '(simulated) INGEST RESPONSE WITH HTML INSTEAD OF JSON',
      redirection:    '(simulated) INGEST REDIRECT ERROR',
      redirect_limit: '(simulated) INGEST "TOO MANY REDIRECTS"'
    }.freeze

    EXCEPTION_METHOD = {
      put_records:    nil,
      delete_records: nil,
      get_records:    DEFAULT_EXCEPTION,
    }.freeze

    # =========================================================================
    # :section:
    # =========================================================================

    private

    FIELD_TYPE = {
      date: %i[
        dcterms_dateAccepted
        dcterms_dateCopyright
        emma_repositoryUpdateDate
        rem_remediationDate
      ],
      string: %i[
        dc_description
        dc_format
        dc_publisher
        dc_rights
        dc_title
        dc_type
        emma_formatVersion
        emma_repository
        emma_repositoryRecordId
        emma_retrievalLink
        emma_webPageLink
        rem_comments
        s_accessibilitySummary
      ],
      array: %i[
        dc_creator
        dc_identifier
        dc_language
        dc_relation
        dc_subject
        emma_collection
        emma_formatFeature
        s_accessibilityAPI
        s_accessibilityControl
        s_accessibilityFeature
        s_accessibilityHazard
        s_accessMode
        s_accessModeSufficient
      ]
    }.deep_freeze

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
      meth = opt[:meth]&.to_sym || calling_method
      inject_exception(meth) and return
      item = opt[:body] || (args[1].is_a?(Array) ? args[1] : args[1..])
      # noinspection RubyMismatchedArgumentType
      inject_fault!(meth, item)
      super
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Injection point for "destructive testing" modifications to message data.
    #
    # @param [Symbol, nil]                            meth  API service method.
    # @param [Ingest::Record::IngestionRecord, Array] item  Target record(s).
    #
    # @return [Integer]               Test cases applied.
    # @return [nil]                   If no injection was performed
    #
    def inject_fault!(meth, item)
      return unless FAULT_INJECTION
      return item.each { inject_fault!(meth, _1) } if item.is_a?(Array)
      return unless (faults = meth ? FAULT_METHOD[meth] : ALL_FAULTS).present?
      unless item.is_a?(Ingest::Record::IngestionRecord)
        Log.warn do
          "#{__method__}: expected IngestionRecord; got #{item.inspect}"
        end unless item.nil?
        return
      end

      __debug_banner("#{meth} #{item.emma_repositoryRecordId} FAULT")
      tests = 0

      # === Bad data for fields expecting single values.
      if SINGLETON_FIELDS_BAD & faults
        tests += 1
        item.rem_comments            = %w[rem_note_1 rem_note_2 rem_note_3]
        item.emma_repositoryRecordId = '.bad,record_id;with/punct'
      end

      # === Bad data for fields expecting single string values.
      # noinspection SpellCheckingInspection
      if STRING_FIELDS_BAD & faults
        tests += 1
        #value = '.bad,%s;with/punct+and"unbalanced double quote'
        value = ".bad,%s;with/punct+and'unbalanced single quote"
        FIELD_TYPE[:string].each do |attr|
          item.send("#{attr}=", (value % attr))
        end
      end

      # === Bad data for fields expecting array values.
      if ARRAY_FIELDS_BAD & faults
        tests += 1
        item.emma_collection        = 'bad collection'
        item.dc_language            = '.bad,language;with/punct'
        item.s_accessibilityFeature = [1, 2, 3]
      end

      # === Bad data for date fields.
      if DATE_FIELDS_BAD & faults
        tests += 1
        item.rem_remediationDate       = 'bad date'
        item.emma_repositoryUpdateDate = '.bad,date;with/punct'
      end

      # === PDF-style dates.
      if PDF_DATES & faults
        tests += 1
        item.rem_remediationDate = "D:20210327195230+05'00'"
      end

      # === Give each field a bogus value.
      if ALL_FIELDS_BAD & faults
        tests += 1
        item.class.instance_methods(false).each do |attr_assignment|
          next unless (name = attr_assignment.to_s.sub!(/=$/, ''))
          item.send(attr_assignment, "xx_#{name}")
        end
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
      set_error(ex)
    end

  else

    protected

    neutralize(:inject_fault!)
    neutralize(:inject_exception)

  end

end

__loading_end(__FILE__)
