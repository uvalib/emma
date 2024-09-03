# app/records/bv_download/message/fetch_response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Acquire file content for downloading from the UVALIB service which hosts
# BiblioVault collections.
#
# Currently there are no data fields associated with the received message; the
# body of the response is the content of the file being downloaded.
#
class BvDownload::Message::FetchResponse < BvDownload::Api::Message

  include BvDownload::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  # No message schema -- response body contains content

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Faraday::Response]
  attr_reader :response

  # Initialize a new instance.
  #
  # @param [Faraday::Response] src
  # @param [Hash, nil]         opt
  #
  def initialize(src, opt = nil)
    @response = src
    super(nil, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The response body.
  #
  # @return [String, nil]
  #
  def content
    response.body.presence
  end

  # The 'Content-Type' header.
  #
  # @return [String]
  #
  def type
    response['Content-Type'] || 'application/octet-stream'
  end

  # The 'Content-Disposition' header.
  #
  # @return [String]
  #
  def disposition
    response['Content-Disposition'] || 'inline'
  end

  # File name from 'Content-Disposition' if present.
  #
  # @return [String, nil]
  #
  def filename
    part = disposition.to_s.split(/\s*;\s*/)
    part.shift # Ignore 'attachment'/'inline'.
    tag, name = part.last&.split('=')
    return if tag.blank? || name.blank?
    case tag
      when 'filename*'
        Log.info { "#{self.class} non-ASCII filename #{disposition.inspect}" }
        if name.include?("''")
          encoding, name = name.split("''")
          encoding = Encoding.find(encoding) || Encoding::UTF_8
          name = CGI.unescape(name, encoding)
        else
          name = CGI.unescape(name)
        end
      when 'filename'
        name.sub!(/^"(.*)"$/, '\1')
      else
        Log.warn { "#{self.class} unexpected #{disposition.inspect}" }
    end
    name
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def to_h
    super.merge!(type: type, filename: filename, content: content)
  end

end

__loading_end(__FILE__)
