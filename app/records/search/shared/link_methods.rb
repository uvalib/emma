# app/records/search/shared/link_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to external repository links.
#
# Attributes supplied by the including module:
#
# @attr [DublinCoreFormat]  dc_format
# @attr [EmmaRepository]    emma_repository
# @attr [String]            emma_repositoryRecordId
# @attr [String]            emma_retrievalLink
#
module Search::Shared::LinkMethods

  include Emma::Common
  include Search

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL of the associated work on the web site of the original repository.
  #
  # @raise [StandardError]            If #REPOSITORY entry is invalid.
  #
  # @return [String]
  # @return [nil]
  #
  def record_title_url
    src   = emma_repository&.to_sym
    entry = REPOSITORY[src].presence or raise 'invalid source'
    path  = entry[:title_path]       or raise 'no title_path'
    make_path(path, emma_repositoryRecordId)
  rescue RuntimeError => error
    # noinspection RubyScope
    Log.warn { "#{__method__}: #{src}: #{error.message}" }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Original repository artifact download URL.
  #
  # @raise [StandardError]            If #REPOSITORY entry is invalid.
  #
  # @return [String]
  # @return [nil]
  #
  def record_download_url
    return emma_retrievalLink if emma_retrievalLink.present?
    id    = emma_repositoryRecordId
    dcfmt = dc_format&.to_sym
    src   = emma_repository&.to_sym
    entry = REPOSITORY[src].presence        or raise 'invalid source'
    fmt   = entry.dig(:download_fmt, dcfmt) or raise "#{dcfmt}: invalid format"
    tag   = 'TAG' # TODO: Bookshare tag
    url   = entry[:download_url]
    url   = url[fmt.to_sym] if url.is_a?(Hash)
    path  = entry[:download_path]
    if path.blank? && (src == DEFAULT_REPOSITORY)
      path = request.base_url if respond_to?(:request)
    end
    raise 'no download_path' if path.blank?
    raise 'no download_url'  if url.blank?
    url % { id: id, fmt: fmt, tag: tag, download_path: path }
  rescue RuntimeError => error
    # noinspection RubyScope
    Log.warn { "#{__method__}: #{src}: #{error.class}: #{error.message}" }
  end

end

__loading_end(__FILE__)
