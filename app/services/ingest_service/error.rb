# app/services/ingest_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Generic exception for Federated Ingest API problems.
#
class IngestService::Error < ApiService::Error

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Methods to be included in related classes.
  #
  module Methods

    # Get the message from within the response body of a Faraday exception.
    #
    # @param [Faraday::Error] error
    #
    # @return [Array<String>]
    #
    # @see #parse_create_errors
    # @see #parse_delete_errors
    #
    # When included in the subclass this method overrides:
    # @see ApiService::Error#extract_message
    #
    def extract_message(error)
      body = error.response[:body].presence
      $stderr.puts "----- INGEST #{self.class} #{__method__} | error = #{body}"
      json = body && json_parse(body, symbolize_keys: false).presence || {}
      json = json.first   if json.is_a?(Array) && (json.size <= 1)
      return json.compact if json.is_a?(Array)
      message =
        if json.is_a?(Hash)
          case json.keys.first.to_s.downcase
            when /^document-\d+/           then parse_create_errors(json)
            when /^[a-z]+-[a-z\d]+-[a-z]+/ then parse_delete_errors(json)
            else                                json
          end
        end
      Array.wrap(message || body)
    end

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
    #     "emma-RID_B-FMT-B" : [ 'Document not found' ],
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

end

class IngestService::NoInputError < ApiService::NoInputError
  include IngestService::Error::Methods
end

class IngestService::EmptyResultError < ApiService::EmptyResultError
  include IngestService::Error::Methods
end

class IngestService::HtmlResultError < ApiService::HtmlResultError
  include IngestService::Error::Methods
end

class IngestService::RedirectionError < ApiService::RedirectionError
  include IngestService::Error::Methods
end

__loading_end(__FILE__)
