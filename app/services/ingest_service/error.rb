# app/services/ingest_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Generic exception for EMMA Unified Ingest API problems.
#
# === Usage Notes
# This is generally *not* the base class for exceptions in the IngestService
# namespace:  Variants based on the error types defined under "emma.error.api"
# are derived from the related ApiService class; e.g.:
#
#   `IngestService::AuthError < ApiService::AuthError`
#
# Only a distinct error type defined under "emma.error.ingest" would derive
# from this class; e.g. if "emma.error.ingest.unique" existed it would be
# defined as:
#
#   `IngestService::UniqueError < IngestService::Error`
#
# An exception in the IngestService namespace can be identified by checking
# for `exception.is_a?(IngestService::Error::ClassType)`.
#
class IngestService::Error < ApiService::Error

  # Methods included in related error classes.
  #
  module ClassType

    include ApiService::Error::ClassType

    # =========================================================================
    # :section: Api::Error::Methods overrides
    # =========================================================================

    public

    # Name of the service and key into config/locales/error.en.yml.
    #
    # @return [Symbol]
    #
    def service
      :ingest
    end

    # =========================================================================
    # :section: ApiService::Error::ClassType overrides
    # =========================================================================

    protected

    # Extract message(s) from a response body that has been determined to be
    # JSON.
    #
    # @param [Hash, *] src
    #
    # @return [Array<String>]         If *json* was a Hash.
    # @return [Array<Any>]            Otherwise.
    #
    # @see #parse_create_errors
    # @see #parse_delete_errors
    #
    def extract_json(src)
      result   = ([] if src.blank?)
      result ||= (src unless src.is_a?(Hash))
      # noinspection RubyMismatchedArgumentType
      result ||=
        case src.keys.first.to_s.downcase
          when /^document-\d+/      then parse_create_errors(src)
          when /^[^-]+-[^-]+-[^-]+/ then parse_delete_errors(src)
          else                           src
        end
      Array.wrap(result || src).compact
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Ingest creation error messages.
    #
    # @param [Hash] src
    #
    # @return [Array<String>]
    #
    # === Implementation Notes
    # The service returns JSON error messages in the response body which
    # indicate one or more specific issues for each problematic item; e.g.:
    #
    #   {
    #     "document-1" : [
    #       " : 'FIELD_A' is a required property",
    #       " : 'FIELD_B' is a required property",
    #       "FIELD_C,N : MESSAGE_CN",
    #       "FIELD_D,M : MESSAGE_DM",
    #       ...
    #     ],
    #     "document-2" : [
    #       " : 'FIELD_E' is a required property",
    #       " : 'FIELD_F' is a required property",
    #       "FIELD_G,N : MESSAGE_GN",
    #       "FIELD_H,M : MESSAGE_HM",
    #       ...
    #     ]
    #   }
    #
    # where the each key is the literal "document" separated by a "-" and the
    # ordinal number of the problematic posted entry.
    #
    def parse_create_errors(src)
      src.map do |key, val|
        issues = []
        key = key.sub(/^.*(\d+)\s*$/, '\1') # Turn "document-123" into "123".
        val = Array.wrap(val)

        # Turn " : 'FIELD_NAME' is a required property" into "FIELD_NAME".
        prop, val = val.partition { |v| v.match?(/required\s+property/i) }
        if prop.present?
          tag  = 'missing field'.pluralize(prop.size) # TODO: I18n
          list = prop.map! { |v| v.sub(/^\W*([\w_]+)\W*.*$/, '\1') }.join(', ')
          issues << "#{tag}: #{list}"
        end

        # Turn "'FIELD_NAME,N' : 'MSG'" into `field[FIELD_NAME] << MSG`.
        if val.present?
          # @type [Hash{String=>Array}]
          field = {}
          val.map! do |v|
            if v.match(/^\s*([^\s,]+),\d+\s*:\s*(.+)\s*$/)
              field[$1] ||= []
              field[$1] << $2.to_s
              next
            end
            v
          end
          val.compact!
          field.each_pair do |fld, errs|
            tag = "field '#{fld}'"
            if errs.size > 1
              list = errs.map.with_index { |err, idx| "#{idx} - '#{err}'" }
            else
              list = "'#{errs.first}'"
            end
            issues << "#{tag}: #{list}"
          end
          issues.concat(val) if val.present?
        end

        issues << 'UNKNOWN PROBLEM' if issues.blank? # TODO: I18n
        "#{key} - %s" % issues.join('; ')
      end
    end

    # Ingest deletion error messages.
    #
    # @param [Hash] src
    #
    # @return [Array<String>]
    #
    # === Usage Notes
    # This is not likely to be invoked because "/recordDeletes" returns with
    # HTTP 202 even if there were errors.  For that reason, the error messages
    # will not be copied into an exception -- they will be found in the
    # message body.
    #
    # === Implementation Notes
    # For deletion of records:
    #
    #   {
    #     "emma-RID_A-FMT_A" : [ 'Document not found' ],
    #     "emma-RID_B-FMT_B" : [ 'Document not found' ],
    #   }
    #
    # where "RID_?" is the repository ID of the offending entry.
    #
    def parse_delete_errors(src)
      src.map do |key, val|
        _repo, rid, _fmt = key.split('-')
        problems = Array.wrap(val).join('; ')
        "#{rid} - #{problems}"
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include IngestService::Error::ClassType

  # ===========================================================================
  # :section: Error classes in this namespace
  # ===========================================================================

  generate_error_classes

end

# Non-functional hints for RubyMine type checking.
# noinspection LongLine
unless ONLY_FOR_DOCUMENTATION
  # :nocov:
  class IngestService::AuthError          < ApiService::AuthError;          include IngestService::Error::ClassType; end # 'en.emma.error.ingest.auth'            || 'en.emma.error.api.auth'
  class IngestService::CommError          < ApiService::CommError;          include IngestService::Error::ClassType; end # 'en.emma.error.ingest.comm'            || 'en.emma.error.api.comm'
  class IngestService::SessionError       < ApiService::SessionError;       include IngestService::Error::ClassType; end # 'en.emma.error.ingest.session'         || 'en.emma.error.api.session'
  class IngestService::ConnectError       < ApiService::ConnectError;       include IngestService::Error::ClassType; end # 'en.emma.error.ingest.connect'         || 'en.emma.error.api.connect'
  class IngestService::TimeoutError       < ApiService::TimeoutError;       include IngestService::Error::ClassType; end # 'en.emma.error.ingest.timeout'         || 'en.emma.error.api.timeout'
  class IngestService::XmitError          < ApiService::XmitError;          include IngestService::Error::ClassType; end # 'en.emma.error.ingest.xmit'            || 'en.emma.error.api.xmit'
  class IngestService::RecvError          < ApiService::RecvError;          include IngestService::Error::ClassType; end # 'en.emma.error.ingest.recv'            || 'en.emma.error.api.recv'
  class IngestService::ParseError         < ApiService::ParseError;         include IngestService::Error::ClassType; end # 'en.emma.error.ingest.parse'           || 'en.emma.error.api.parse'
  class IngestService::RequestError       < ApiService::RequestError;       include IngestService::Error::ClassType; end # 'en.emma.error.ingest.request'         || 'en.emma.error.api.request'
  class IngestService::NoInputError       < ApiService::NoInputError;       include IngestService::Error::ClassType; end # 'en.emma.error.ingest.no_input'        || 'en.emma.error.api.no_input'
  class IngestService::ResponseError      < ApiService::ResponseError;      include IngestService::Error::ClassType; end # 'en.emma.error.ingest.response'        || 'en.emma.error.api.response'
  class IngestService::EmptyResultError   < ApiService::EmptyResultError;   include IngestService::Error::ClassType; end # 'en.emma.error.ingest.empty_result'    || 'en.emma.error.api.empty_result'
  class IngestService::HtmlResultError    < ApiService::HtmlResultError;    include IngestService::Error::ClassType; end # 'en.emma.error.ingest.html_result'     || 'en.emma.error.api.html_result'
  class IngestService::RedirectionError   < ApiService::RedirectionError;   include IngestService::Error::ClassType; end # 'en.emma.error.ingest.redirection'     || 'en.emma.error.api.redirection'
  class IngestService::RedirectLimitError < ApiService::RedirectLimitError; include IngestService::Error::ClassType; end # 'en.emma.error.ingest.redirect_limit'  || 'en.emma.error.api.redirect_limit'
  # :nocov:
end

__loading_end(__FILE__)
