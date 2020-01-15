# app/controllers/concerns/search_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchConcern
#
module SearchConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'SearchConcern')
  end

  include FilesConcern
  include SearchHelper

  # ===========================================================================
  # :section: Initialization
  # ===========================================================================

=begin
  if Log.info?
    extend TimeHelper
    # Log API request times.
    ActiveSupport::Notifications.subscribe('request.faraday') do |*args|
      _name    = args.shift # 'request.faraday'
      starts   = args.shift
      ends     = args.shift
      _payload = args.shift
      env      = args.shift
      method   = env[:method].to_s.upcase
      url      = env[:url]
      host     = url.host
      uri      = url.request_uri
      duration = time_span(starts.to_f, ends.to_f)
      Log.info { '[%s] %s %s (%s)' % [host, method, uri, duration] }
    end
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Retrieve embedded metadata information from the indicated file (which is
  # downloaded if it is not already present in the download cache).
  #
  # @param [ActionController::Parameters, Hash] opt  Passed to
  #                                   #extract_file_properties except for:
  #
  # @option opt [String] :path        URL or directory path to file.
  # @option opt [String] :url         Alias for :path.
  #
  # @return [Hash{repo: String, id: String, fmt: Symbol, info: Hash}] where:
  #
  #   repo: The repository portion of the complete file name.
  #   id:   The repositoryId portion of the complete file name.
  #   fmt:  The file format extension of the complete file name.
  #   info: Metadata values extracted from the file (@see #file_info_values).
  #
  # == Usage Notes
  # If :path is not given it will be derived from the other provided options.
  #
  def get_file_details(opt)
    __debug_args(binding)
    opt, prop = partition_options(opt, :path, :url)
    path = opt[:path] || opt[:url]
    prop = extract_file_properties(path, prop)
    path ||= RemoteFile.make_download_path(prop)
    {
      repo: prop.repository,
      id:   prop.repository_id,
      fmt:  prop.fmt,
      info: file_info_values(path, **prop)
    }
  end

  # Eliminate values from keys that would be problematic when rendering the
  # hash as JSON or XML.
  #
  # @overload normalize_keys(value)
  #   @param [Hash] value
  #   @return [Hash]
  #
  # @overload normalize_keys(value)
  #   @param [Array] value
  #   @return [Array]
  #
  # @overload normalize_keys(value)
  #   @param [String] value
  #   @return [String]
  #
  # @overload normalize_keys(value)
  #   @param [*] value
  #   @return [*]
  #
  def normalize_keys(value)
    if value.is_a?(Hash)
      value
        .transform_keys   { |k| k.to_s.downcase.tr('^a-z0-9_', '_') }
        .transform_values { |v| normalize_keys(v) }
    elsif value.is_a?(Array) && (value.size > 1)
      value.map { |v| normalize_keys(v) }
    elsif value.is_a?(Array)
      normalize_keys(value.first)
    elsif value.is_a?(String) && value.include?(FF_SEPARATOR)
      value.split(FF_SEPARATOR).reject(&:blank?)
    else
      value
    end
  end

end

__loading_end(__FILE__)
