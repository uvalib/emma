# app/helpers/repository_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting variations for the member repositories.
#
module RepositoryHelper

  def self.included(base)
    __included(base, '[RepositoryHelper]')
  end

  include HtmlHelper
  include ArtifactHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # HathiTrust parameters which cause a prompt for login.
  #
  # @type [String]
  #
  #--
  # noinspection SpellCheckingInspection
  #++
  HT_URL_PARAMS = 'urlappend=%3Bsignon=swle:wayf'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the given URL is an EMMA link.
  #
  # @param [String] url
  #
  def emma_link?(url)
    url.to_s.match?(%r{^https?://emma[^/]*\.virginia\.edu/})
  end

  # Indicate whether the given URL is a Bookshare link.
  #
  # @param [String] url
  #
  # == Usage Notes
  # This exists to support the handful of items which are represented as
  # belonging to the "EMMA" repository but which are actually Bookshare items
  # from the "EMMA Collection".
  #
  def bs_link?(url)
    url.to_s.match?(%r{^https?://([^/]+\.)?bookshare\.org/})
  end

  # Indicate whether the given URL is an Internet Archive link.
  #
  # @param [String] url
  #
  def ht_link?(url)
    url.to_s.match?(%r{^https?://([^/]+\.)?handle\.net/})
  end

  # Indicate whether the given URL is an Internet Archive link.
  #
  # @param [String] url
  #
  def ia_link?(url)
    url.to_s.match?(%r{^https?://([^/]+\.)?archive\.org/})
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce a link to retrieve an EMMA file.
  #
  # @param [Api::Record] _item        Unused.
  # @param [String]       label
  # @param [String]       url
  # @param [Hash]         opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see HtmlHelper#download_link
  #
  def emma_retrieval_link(_item, label, url, **opt)
    url = url.sub(%r{localhost:\d+}, 'localhost') unless application_deployed?
    download_link(label, url, **opt)
  end

  # Produce a control to manage download of a Bookshare item artifact.
  #
  # @param [Api::Record] item
  # @param [String]      label
  # @param [String]      url
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see ArtifactHelper#download_links
  #
  def bs_retrieval_link(item, label, url, **opt)
    download_links(item, label: label, url: url, **opt)
  end

  # Produce a link to open a new browser tab to retrieve a file from the
  # HathiTrust web site.
  #
  # @param [Api::Record] _item        Unused.
  # @param [String]       label
  # @param [String]       url
  # @param [Hash]         opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see HtmlHelper#download_link
  #
  def ht_retrieval_link(_item, label, url, **opt)
    url_params    = url.split('?', 2)[1]
    has_ht_params = url_params&.split('&')&.include?(HT_URL_PARAMS)
    url += (url_params ? '&' : '?') + HT_URL_PARAMS unless has_ht_params
    download_link(label, url, **opt)
  end

  # Produce a link to retrieve an Internet Archive file.
  #
  # @param [Api::Record] _item        Unused.
  # @param [String]       label
  # @param [String]       url
  # @param [Hash]         opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see HtmlHelper#download_link
  #
  def ia_retrieval_link(_item, label, url, **opt)
    download_link(label, retrieval_path(url: url), **opt)
  end

end

__loading_end(__FILE__)
