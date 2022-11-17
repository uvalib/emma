# app/helpers/repository_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting variations for the member repositories.
#
module RepositoryHelper

  include LinkHelper

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

  # Internet Archive items that don't require EMMA login.
  #
  # @type [Array<String,Regexp>]
  #
  IA_DIRECT_LINK_PATTERNS = [
    /[_.]daisy\.zip$/,
  ].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the given URL is an EMMA link.
  #
  # @param [String, nil] url
  #
  def emma_link?(url)
    url.to_s.strip.match?(%r{^https?://emma[^/]*\.virginia\.edu/})
  end

  # Indicate whether the given URL is a Bookshare link.
  #
  # @param [String, nil] url
  #
  # == Usage Notes
  # This exists to support the handful of items which are represented as
  # belonging to the "EMMA" repository but which are actually Bookshare items
  # from the "EMMA Collection".
  #
  def bs_link?(url)
    url.to_s.strip.match?(%r{^https?://([^/]+\.)?bookshare\.org/})
  end

  # Indicate whether the given URL is a HathiTrust link.
  #
  # @param [String, nil] url
  #
  def ht_link?(url)
    url.to_s.strip.match?(%r{^https?://([^/]+\.)?handle\.net/})
  end

  # Indicate whether the given URL is an Internet Archive link.
  #
  # @param [String, nil] url
  #
  def ia_link?(url)
    url.to_s.strip.match?(%r{^https?://([^/]+\.)?archive\.org/})
  end

  # Report the member repository associated with the given URL.
  #
  # @param [String]               url
  # @param [Symbol, Boolean, nil] default   *true* => `EmmaRepository#default`.
  #
  # @return [String]                  One of EmmaRepository#values.
  # @return [nil]                     If not associated with any repository.
  #
  def url_repository(url, default: nil)
    result =
      (:emma                  if emma_link?(url))          ||
      (:bookshare             if bs_link?(url))            ||
      (:hathiTrust            if ht_link?(url))            ||
      (:internetArchive       if ia_link?(url))            ||
      (EmmaRepository.default if default.is_a?(TrueClass)) ||
      default.presence
    result&.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce a link to retrieve an EMMA file.
  #
  # @param [Api::Record, nil] _item   Unused.
  # @param [String]            label
  # @param [String]            url
  # @param [Hash]              opt    Passed to #retrieval_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emma_retrieval_link(_item, label, url, **opt)
    url = url.sub(%r{localhost:\d+}, 'localhost') unless application_deployed?
    retrieval_link(label, url, **opt)
  end

  # Produce a control to manage download of a Bookshare item artifact.
  #
  # @param [Api::Record] item
  # @param [String]      label
  # @param [String]      url
  # @param [Hash]        opt          To BookshareDecorator#artifact_links
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bs_retrieval_link(item, label, url, **opt)
    BookshareDecorator.artifact_links(item, label: label, url: url, **opt)
  end

  # Produce a link to open a new browser tab to retrieve a file from the
  # HathiTrust web site.
  #
  # @param [Api::Record, nil] _item   Unused.
  # @param [String]            label
  # @param [String]            url
  # @param [Hash]              opt    Passed to #retrieval_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def ht_retrieval_link(_item, label, url, **opt)
    url_params    = url.split('?', 2)[1]
    has_ht_params = url_params&.split('&')&.include?(HT_URL_PARAMS)
    url += (url_params ? '&' : '?') + HT_URL_PARAMS unless has_ht_params
    retrieval_link(label, url, **opt)
  end

  # Produce a link to retrieve an Internet Archive file.
  #
  # @param [Api::Record, nil] _item   Unused.
  # @param [String]            label
  # @param [String]            url
  # @param [Hash]              opt    Passed to #retrieval_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Implementation Notes
  # Encrypted DAISY files are handled differently; for an explanation:
  # @see IaDownloadConcern#ia_download_response
  #
  def ia_retrieval_link(_item, label, url, **opt)
    direct = IA_DIRECT_LINK_PATTERNS.any? { |pattern| url.match?(pattern) }
    url    = retrieval_path(url: url) unless direct
    retrieval_link(label, url, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Produce a link to retrieve a content file.
  #
  # @param [String] label
  # @param [String] url
  # @param [Hash]   opt               Passed to LinkHelper#download_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def retrieval_link(label, url, **opt)
    opt.delete(:context) # In case this was invoked from a decorator.
    download_link(label, url, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
