# app/records/search/shared/link_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'sanitize'

# Methods mixed in to record elements related to external repository links.
#
module Search::Shared::LinkMethods

  include Search
  include GenericHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Values that are applicable to FileProperties.
  #
  # @return [Hash]
  #
  def file_properties
    {
      repository:   emma_repository,
      repositoryId: emma_repositoryRecordId,
      fmt:          dc_format
    }.compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL of the associated work on the web site of the original repository.
  #
  # @return [String]
  # @return [nil]
  #
  def record_title_url
    src   = emma_repository&.to_sym
    entry = REPOSITORY[src].presence or raise 'invalid source'
    path  = entry[:title_path]       or raise 'no title_path'
    make_path(path, emma_repositoryRecordId)
  rescue RuntimeError => e
    # noinspection RubyScope
    Log.warn { "#{__method__}: #{src}: #{e.message}" }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Original repository artifact download URL.
  #
  # @return [String]
  # @return [nil]
  #
  def record_download_url
    return emma_retrievalLink if emma_retrievalLink.present?
    id    = emma_repositoryRecordId
    fmt   = dc_format&.to_sym
    src   = emma_repository&.to_sym
    entry = REPOSITORY[src].presence      or raise 'invalid source'
    path  = entry[:download_path]         or raise 'no download_path'
    fmt   = entry.dig(:download_fmt, fmt) or raise "#{fmt}: invalid format"
    tag   = 'TAG' # TODO: Bookshare tag
    url   = entry[:download_url]
    url   = url[fmt.to_sym] if url.is_a?(Hash)
    raise 'no download_url' unless url.present?
    url % { id: id, fmt: fmt, tag: tag, download_path: path }
  rescue RuntimeError => e
    # noinspection RubyScope
    Log.warn { "#{__method__}: #{src}: #{e.message}" }
  end

end

__loading_end(__FILE__)
