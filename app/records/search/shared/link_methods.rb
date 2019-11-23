# app/records/search/shared/link_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'sanitize'

# Methods mixed in to record elements related to external repository links.
#
module Search::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  BS_ROOT          = 'https://www.bookshare.org'
  BS_TITLE_PATH    = "#{BS_ROOT}/browse/book"
  BS_DOWNLOAD_PATH = "#{BS_ROOT}/bookHistory/download/book"

  HT_ROOT          = 'https://catalog.hathitrust.org'
  HT_TITLE_PATH    = "#{HT_ROOT}/Record"
  HT_DOWNLOAD_PATH = 'https://babel.hathitrust.org/cgi/imgsrv/download'

  IA_ROOT          = 'https://archive.org'
  IA_TITLE_PATH    = "#{IA_ROOT}/details"
  IA_DOWNLOAD_PATH = "#{IA_ROOT}/download"

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # title_url
  #
  # @param [Search::Api::Record] item
  #
  # @return [String]
  # @return [nil]
  #
  def title_url(item)
    item = self if item.nil? && self.is_a?(Search::Api::Record)
    case item.emma_repository
      when 'bookshare'       then bookshare_title_url(item)
      when 'hathiTrust'      then ht_title_url(item)
      when 'internetArchive' then ia_title_url(item)
    end
  end

  # bookshare_title_url
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt
  #
  # @option opt [String] :id          Title ID.
  # @option opt [String] :fmt         Download format.
  #
  # @return [String]
  #
  def bookshare_title_url(item, **opt)
    item = self if item.nil? && self.is_a?(Search::Api::Record)
    id   = opt[:id].presence || item&.emma_repositoryRecordId
    "#{BS_TITLE_PATH}/#{id}"
  end

  # ht_title_url
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt
  #
  # @option opt [String] :id          Title ID.
  #
  # @return [String]
  #
  def ht_title_url(item, **opt)
    item = self if item.nil? && self.is_a?(Search::Api::Record)
    id   = opt[:id].presence || item&.emma_repositoryRecordId
    "#{HT_TITLE_PATH}/#{id}"
  end

  # ia_title_url
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt
  #
  # @option opt [String] :id          Title ID.
  #
  # @return [String]
  #
  def ia_title_url(item, **opt)
    item = self if item.nil? && self.is_a?(Search::Api::Record)
    id   = opt[:id].presence || item&.emma_repositoryRecordId
    "#{IA_TITLE_PATH}/#{id}"
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # download_url
  #
  # @param [Search::Api::Record] item
  #
  # @return [String]
  # @return [nil]
  #
  def download_url(item = nil)
    item = self if item.nil? && self.is_a?(Search::Api::Record)
    item.emma_retrievalLink.presence ||
      case item.emma_repository
        when 'bookshare'       then bookshare_download_url(item)
        when 'hathiTrust'      then ht_download_url(item)
        when 'internetArchive' then ia_download_url(item)
      end
  end

  # bookshare_download_url
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt
  #
  # @option opt [String] :id          Title ID.
  # @option opt [String] :fmt         Download format.
  #
  # @return [String]
  #
  def bookshare_download_url(item, **opt)
    item = self if item.nil? && self.is_a?(Search::Api::Record)
    id   = opt[:id].presence  || item&.emma_repositoryRecordId
    fmt  = opt[:fmt].presence || item&.dc_format
    tag  = opt[:tag].presence || '18034728' # TODO: ???
    case fmt
      when 'brf'        then fmt = 'BRF'
      when 'daisy'      then fmt = 'DAISY'
      when 'daisyAudio' then fmt = 'DAISY_AUDIO'
      when 'epub'       then fmt = 'EPUB3'
      when 'braille'    then fmt = 'BRF?'
      when 'pdf'        then fmt = 'PDF'
      when 'word'       then fmt = 'DOCX'
      when 'tactile'    then fmt = 'BRF?'
      when 'kurzweil'   then fmt = 'BRF?'
      when 'rtf'        then fmt = 'TEXT?'
      when '???'        then fmt = 'HTML' # NOTE: not in schema
    end
    "#{BS_DOWNLOAD_PATH}?" \
      "titleInstanceId=#{id}&downloadFormat=#{fmt}&tag=#{tag}"
  end

  # ht_download_url
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt
  #
  # @option opt [String] :id          Title ID.
  # @option opt [String] :fmt         Download format.
  #
  # @return [String]
  #
  def ht_download_url(item, **opt)
    item = self if item.nil? && self.is_a?(Search::Api::Record)
    id   = opt[:id].presence  || item&.emma_repositoryRecordId
    fmt  = opt[:fmt].presence || item&.dc_format
    case fmt # TODO: HT download formats
      when 'brf'        then fmt = 'brf'
      when 'daisy'      then fmt = 'daisy'
      when 'daisyAudio' then fmt = 'daisyAudio'
      when 'epub'       then fmt = 'epub'
      when 'braille'    then fmt = 'braille'
      when 'pdf'        then fmt = 'pdf'
      when 'word'       then fmt = 'word'
      when 'tactile'    then fmt = 'tactile'
      when 'kurzweil'   then fmt = 'kurzweil'
      when 'rtf'        then fmt = 'rtf'
    end
    "#{HT_DOWNLOAD_PATH}/#{fmt}?id=#{id}"
  end

  # ia_download_url
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt
  #
  # @option opt [String] :id          Title ID.
  # @option opt [String] :fmt         Download format.
  #
  # @return [String]
  #
  def ia_download_url(item, **opt)
    item = self if item.nil? && self.is_a?(Search::Api::Record)
    id   = opt[:id].presence  || item&.emma_repositoryRecordId
    fmt  = opt[:fmt].presence || item&.dc_format
    case fmt # TODO: IA download formats
      when 'brf'        then fmt = 'brf'
      when 'daisy'      then fmt = 'daisy'
      when 'daisyAudio' then fmt = 'daisyAudio'
      when 'epub'       then fmt = 'epub'
      when 'braille'    then fmt = 'braille'
      when 'pdf'        then fmt = 'pdf'
      when 'word'       then fmt = 'word'
      when 'tactile'    then fmt = 'tactile'
      when 'kurzweil'   then fmt = 'kurzweil'
      when 'rtf'        then fmt = 'rtf'
    end
    "#{IA_DOWNLOAD_PATH}/#{id}/#{id}_#{fmt}.zip"
  end

end

__loading_end(__FILE__)
