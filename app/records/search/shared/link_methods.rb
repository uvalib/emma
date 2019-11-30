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

  # URL of the associated work on the web site of the original repository.
  #
  # @param [Search::Api::Record] item
  #
  # @return [String]
  # @return [nil]
  #
  def record_title_url(item = nil)
    item, opt = link_properties(item)
    src   = item&.emma_repository&.to_sym
    entry = REPOSITORY[src].presence or raise 'invalid source'
    path  = entry[:title_path]       or raise 'no title_path'
    make_path(path, opt[:id]) if opt[:id].present?
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
  # @param [Search::Api::Record] item
  #
  # @return [String]
  # @return [nil]
  #
  def record_download_url(item = nil)
    item, opt = link_properties(item)
    src    = item&.emma_repository&.to_sym
    link   = item&.emma_retrievalLink
    return link if link.present?
    fmt    = opt[:fmt]&.to_sym
    entry  = REPOSITORY[src].presence      or raise 'invalid source'
    path   = entry[:download_path]         or raise 'no download_path'
    url    = entry[:download_url]          or raise 'no download_url'
    format = entry.dig(:download_fmt, fmt) or raise "#{fmt}: invalid format"
    url % opt.reverse_merge(download_path: path, fmt: format, tag: '')
  rescue RuntimeError => e
    # noinspection RubyScope
    Log.warn { "#{__method__}: #{src}: #{e.message}" }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # link_properties
  #
  # @param [Search::Api::Record, nil] item
  # @param [Hash]                     opt
  #
  # @option opt [String] :id          Title ID.
  # @option opt [String] :fmt         Download format.
  #
  # @return [Array<(Search::Api::Record,Hash)>]
  # @return [Array<(nil,Hash)>]
  #
  def link_properties(item, **opt)
    item ||= (self if self.respond_to?(:emma_repositoryRecordId))
    opt = opt.reject { |_, v| v.blank? }
    opt[:id]  ||= item.emma_repositoryRecordId if item
    opt[:fmt] ||= item.dc_format               if item
    return item, opt
  end

end

__loading_end(__FILE__)
