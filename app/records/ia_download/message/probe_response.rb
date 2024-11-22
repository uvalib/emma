# app/records/ia_download/message/probe_response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Determine the readiness of a file for download via the Internet Archive
# "Printdisabled Unencrypted Ebook API".
#
class IaDownload::Message::ProbeResponse < IaDownload::Api::Message

  include IaDownload::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from IaDownload::Record::ResponseRecord

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the file is ready for download.
  #
  # @return [Boolean]
  #
  attr_reader :ready

  # Indicate whether the file is currently being generated on-the-fly.
  #
  # @return [Boolean]
  #
  attr_reader :waiting

  # Indicate whether the file is unavailable.
  #
  # @return [Boolean]
  #
  attr_reader :error

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Hash, nil] src
  # @param [Hash, nil]                    opt
  #
  def initialize(src, opt = nil)
    @waiting = @ready = @error = false
    super(src, opt)
    if status.to_i.zero?
      self.status =
        case src
          when Hash              then src[:status]
          when Faraday::Response then src.status
        end
    end
    case status
      when 202      then @waiting = true
      when 200..299 then @ready   = true
      else               @error   = true
    end
    if @error && message.blank?
      # noinspection RubyMismatchedArgumentType
      self.message =
        case src
          when Hash
            src[:message]
          when Faraday::Response
            IaDownloadService::Error.extract_message(src)
        end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def to_h
    super.merge!(ready: ready, waiting: waiting, error: error)
  end

end

__loading_end(__FILE__)
