# app/controllers/concerns/import_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods importing files via the HTTP request.
#
module ImportConcern

  extend ActiveSupport::Concern

  include Emma::Common
  include Emma::Csv
  include Emma::Json

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Remote or locally-provided data.
  #
  # @param [String,ActionDispatch::Http::UploadedFile]        src   URI/path.
  # @param [String,ActionDispatch::Request,Faraday::Response] data  Raw data.
  # @param [Symbol]                                           type  Media type.
  #
  # @raise [RuntimeError]             If both *src* and *data* are present.
  #
  # @return [Array<Hash>]
  # @return [nil]                     If both *src* and *data* are missing.
  #
  # === Usage Notes
  # If the source is in the request body and not given by either `params[:src]`
  # or `params[:data]` then `params[:type]` must be present to indicate the
  # media type of the source being supplied via `request.body` (or `req.body`).
  #
  def fetch_data(src: nil, data: nil, type: nil, **)
    __debug_items("IMPORT #{__method__}", binding)
    raise "#{__method__}: both :src and :data were given" if src && data
    if data
      data, _ = extract_from(data) unless data.is_a?(String)
      type ||= request.media_type.to_s.downcase.remove(%r{^[^/]+/}).to_sym
    elsif src
      data, name = extract_from(src)
      type ||= name.to_s.downcase.split('.').last&.to_sym || :text
    end
    # noinspection RubyMismatchedArgumentType
    case type
      when nil   then Log.warn { "#{__method__}: no :src or :data" }
      when :csv  then from_csv(data)
      when :json then from_json(data)
      else            from_json(data) || from_csv(data)
    end
  end

  # Interpret data as JSON.
  #
  # @param [String, IO, StringIO, IO::Like] data
  #
  # @return [Array<Hash>, nil]
  #
  def from_json(data)
    result = json_parse(data)
    data.rewind rescue nil if data.respond_to?(:rewind)
    result && Array.wrap(result)
  end

  # Interpret data as CSV.
  #
  # @param [String, IO, StringIO, IO::Like] data
  #
  # @return [Array<Hash>, nil]
  #
  def from_csv(data)
    result = csv_parse(data)
    data.rewind rescue nil if data.respond_to?(:rewind)
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get data and source name in a usable form.
  #
  # @param [any] src
  #
  # @return [Array<(IO, String)>]
  # @return [Array<(String, String)>]
  # @return [Array<(String, nil)>]
  # @return [Array<(nil, nil)>]
  #
  def extract_from(src)
    case src
      when ActionDispatch::Http::UploadedFile         # Embedded file data.
        return src.open, src.original_filename
      when ActionDispatch::Request, Faraday::Response # Embedded file data.
        return src.body, nil
      when /^https?:/                                 # Remote file URI.
        return Faraday.get(src).body, src
      when String                                     # Local file path.
        return File.open(src), src
      else
        raise "unexpected source type #{src.class}"
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
