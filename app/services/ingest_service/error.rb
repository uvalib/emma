# app/services/ingest_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Generic exception for Federated Ingest API problems.
#
class IngestService::Error < ApiService::Error

  # Methods to be included in related classes.
  #
  module Methods

    def self.included(base)
      base.send(:extend, self)
    end

    # Non-functional hints for RubyMine type checking.
    # :nocov:
    include ApiService::Error::Methods unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    # =========================================================================
    # :section: ApiService::Error::Methods overrides
    # =========================================================================

    public

    # Name of the service and key into config/locales/error.en.yml.
    #
    # @return [Symbol]
    #
    def service
      :ingest
    end

    # Get the message from within the response body of a Faraday exception.
    #
    # @param [Faraday::Error] error
    #
    # @return [Array<String>]
    #
    # @see #parse_create_errors
    # @see #parse_delete_errors
    #
    def extract_message(error)
      body = error.response[:body].presence
      json = body && json_parse(body, symbolize_keys: false).presence || {}
      json = json.first   if json.is_a?(Array) && (json.size <= 1)
      return json.compact if json.is_a?(Array)
      message =
        if json.is_a?(Hash)
          case json.keys.first.to_s.downcase
            when /^document-\d+/      then parse_create_errors(json)
            when /^[^-]+-[^-]+-[^-]+/ then parse_delete_errors(json)
            else                           json
          end
        end
      Array.wrap(message || body)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Ingest creation error messages.
    #
    # @param [Hash] message
    #
    # @return [Array<String>]
    #
    # == Implementation Notes
    # The ingest service returns JSON error messages in the response body which
    # indicate one or more specific issues for each problematic item; e.g.:
    #
    #   {
    #     "document-1" : [
    #       " : 'ITEM_A' is a required property",
    #       " : 'ITEM_B' is a required property",
    #       ...
    #     ],
    #     "document-2" : [
    #       " : 'ITEM_C' is a required property",
    #       " : 'ITEM_D' is a required property",
    #       ...
    #     ]
    #   }
    #
    # where the each key is the literal "document" separated by a "-" and the
    # ordinal number of the problematic posted entry.
    #
    def parse_create_errors(message)
      message.map do |key, val|
        key = key.sub(/^.*(\d+)\s*$/, '\1') # Turn "document-123" into "123".
        val = Array.wrap(val)
        prop, val = val.partition { |v| v.match?(/required\s+property/i) }
        if prop.present?
          # Turn " : 'FIELD_NAME' is a required property" into "FIELD_NAME".
          prop.map! { |v| v.sub(/^\W*([\w_]+)\W*.*$/, '\1') }
          fields = 'missing field'.pluralize(prop.size) # TODO: I18n
          fields << ': ' << prop.join(', ')
          val.prepend(fields)
        end
        val << 'UNKNOWN PROBLEM' if val.blank? # TODO: I18n
        problems = val.join('; ')
        "#{key} - #{problems}"
      end
    end

    # Ingest deletion error messages.
    #
    # @param [Hash] message
    #
    # @return [Array<String>]
    #
    # == Usage Notes
    # This is not likely to be invoked because "/recordDeletes" returns with
    # HTTP 202 even if there were errors.  For that reason, the error messages
    # will not be copied into an exception -- they will be found in the
    # message body.
    #
    # == Implementation Notes
    # For deletion of records:
    #
    #   {
    #     "emma-RID_A-FMT_A" : [ 'Document not found' ],
    #     "emma-RID_B-FMT_B" : [ 'Document not found' ],
    #   }
    #
    # where "RID_?" is the repository ID of the offending entry.
    #
    def parse_delete_errors(message)
      message.map do |key, val|
        _repo, rid, _fmt = key.split('-')
        problems = Array.wrap(val).join('; ')
        "#{rid} - #{problems}"
      end
    end

  end

  include IngestService::Error::Methods

  # ===========================================================================
  # :section: Error subclasses
  # ===========================================================================

  generate_error_subclasses

end

# Non-functional hints for RubyMine type checking.
# noinspection LongLine, DuplicatedCode
# :nocov:
unless ONLY_FOR_DOCUMENTATION
  class IngestService::AuthError          < ApiService::AuthError;          include IngestService::Error::Methods; end # 'en.emma.error.ingest.auth'            || 'en.emma.error.api.auth'
  class IngestService::CommError          < ApiService::CommError;          include IngestService::Error::Methods; end # 'en.emma.error.ingest.comm'            || 'en.emma.error.api.comm'
  class IngestService::SessionError       < ApiService::SessionError;       include IngestService::Error::Methods; end # 'en.emma.error.ingest.session'         || 'en.emma.error.api.session'
  class IngestService::ConnectError       < ApiService::ConnectError;       include IngestService::Error::Methods; end # 'en.emma.error.ingest.connect'         || 'en.emma.error.api.connect'
  class IngestService::TimeoutError       < ApiService::TimeoutError;       include IngestService::Error::Methods; end # 'en.emma.error.ingest.timeout'         || 'en.emma.error.api.timeout'
  class IngestService::XmitError          < ApiService::XmitError;          include IngestService::Error::Methods; end # 'en.emma.error.ingest.xmit'            || 'en.emma.error.api.xmit'
  class IngestService::RecvError          < ApiService::RecvError;          include IngestService::Error::Methods; end # 'en.emma.error.ingest.recv'            || 'en.emma.error.api.recv'
  class IngestService::ParseError         < ApiService::ParseError;         include IngestService::Error::Methods; end # 'en.emma.error.ingest.parse'           || 'en.emma.error.api.parse'
  class IngestService::RequestError       < ApiService::RequestError;       include IngestService::Error::Methods; end # 'en.emma.error.ingest.request'         || 'en.emma.error.api.request'
  class IngestService::NoInputError       < ApiService::NoInputError;       include IngestService::Error::Methods; end # 'en.emma.error.ingest.no_input'        || 'en.emma.error.api.no_input'
  class IngestService::ResponseError      < ApiService::ResponseError;      include IngestService::Error::Methods; end # 'en.emma.error.ingest.response'        || 'en.emma.error.api.response'
  class IngestService::EmptyResultError   < ApiService::EmptyResultError;   include IngestService::Error::Methods; end # 'en.emma.error.ingest.empty_result'    || 'en.emma.error.api.empty_result'
  class IngestService::HtmlResultError    < ApiService::HtmlResultError;    include IngestService::Error::Methods; end # 'en.emma.error.ingest.html_result'     || 'en.emma.error.api.html_result'
  class IngestService::RedirectionError   < ApiService::RedirectionError;   include IngestService::Error::Methods; end # 'en.emma.error.ingest.redirection'     || 'en.emma.error.api.redirection'
  class IngestService::RedirectLimitError < ApiService::RedirectLimitError; include IngestService::Error::Methods; end # 'en.emma.error.ingest.redirect_limit'  || 'en.emma.error.api.redirect_limit'
end
# :nocov:

__loading_end(__FILE__)
