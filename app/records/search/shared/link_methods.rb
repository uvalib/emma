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
# @attr [String]            emma_webPageLink
# @attr [String]            emma_retrievalLink
#
module Search::Shared::LinkMethods

  include Emma::Common
  include Api::Common
  include Search::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL of the associated work on the web site of the original repository.
  #
  # @return [String, nil]
  #
  def record_title_url
    emma_webPageLink.presence || generate_title_url
  end

  # Original repository content file download URL.
  #
  # @raise [RuntimeError]             If #REPOSITORY entry is invalid.
  #
  # @return [String, nil]
  #
  def record_download_url
    emma_retrievalLink.presence || generate_download_url
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a URL manufactured from 'en.emma.repository.*.title_path' for the
  # associated work on the web site of the original repository.
  #
  # @raise [RuntimeError]             If #REPOSITORY entry is invalid.
  #
  # @return [String, nil]
  #
  def generate_title_url
    id   = emma_repositoryRecordId&.presence or return
    src  = emma_repository&.presence&.to_sym or return
    cfg  = REPOSITORY[src].presence          or raise "#{src}: invalid source"
    path = cfg[:title_path]                  or raise 'no title_path'
    if respond_to?(:request) && (src.to_s == EmmaRepository.default)
      path = request.base_url + path if path.start_with?('/')
    end
    make_path(path, id)
  rescue RuntimeError => error
    # noinspection RubyScope
    Log.warn { "#{__method__}: #{src}: #{error.message}" }
  end

  # Create a URL on the original repository for acquiring the content file
  # associated with the item.
  #
  # @raise [RuntimeError]             If #REPOSITORY entry is invalid.
  #
  # @return [String, nil]
  #
  def generate_download_url
    id   = emma_repositoryRecordId&.presence or return
    src  = emma_repository&.presence&.to_sym or return
    fmt  = dc_format&.presence&.to_sym       or return
    cfg  = REPOSITORY[src].presence          or raise "#{src}: invalid source"
    fmt  = cfg.dig(:download_fmt, fmt)       or raise "#{fmt}: invalid format"
    url  = cfg[:download_url]
    url  = url[fmt] if url.is_a?(Hash)
    path = cfg[:download_path]
    if respond_to?(:request) && (src.to_s == EmmaRepository.default)
      if path.blank?
        path = request.base_url
      elsif path.start_with?('/')
        path = request.base_url + path
      end
    end
    raise 'no download_path' if path.blank?
    raise 'no download_url'  if url.blank?
    url % { id: id, fmt: fmt, download_path: path }
  rescue RuntimeError => error
    # noinspection RubyScope
    Log.warn { "#{__method__}: #{src}: #{error.class}: #{error.message}" }
  end

end

__loading_end(__FILE__)
