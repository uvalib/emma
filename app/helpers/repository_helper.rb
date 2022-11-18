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
  # ACE/ScholarsPortal items are hosted by Internet Archive with download links
  # which are indistinguishable.
  #
  # @param [String, nil] url
  #
  def ia_link?(url)
    url.to_s.strip.match?(%r{^https?://([^/]+\.)?archive\.org/})
  end

  # Report the member repository associated with the given URL.
  #
  # @param [String, nil] url
  #
  # @return [String]                  One of EmmaRepository#values.
  # @return [nil]                     If not associated with any repository.
  #
  def url_repository(url)
    return unless url.present?
    # noinspection RubyCaseWithoutElseBlockInspection
    case
      when emma_link?(url) then :emma
      when bs_link?(url)   then :bookshare
      when ht_link?(url)   then :hathiTrust
      when ia_link?(url)   then :internetArchive
    end&.to_s
  end

  # Report the member repository as indicated by the given parameters.
  #
  # To account for the handful of "EMMA" items that are actually Bookshare
  # items from the "EMMA collection", if both a String (URL) and Model/Hash are
  # given, change the reported repository based on the nature of the URL.
  #
  # @param [Model, Hash, String, nil] arg1
  # @param [Model, Hash, String, nil] arg2
  #
  # @return [String]                  One of EmmaRepository#values.
  # @return [nil]                     If not associated with any repository.
  #
  def repository_for(arg1, arg2 = nil)
    obj, url = arg1.is_a?(String) ? [arg2, arg1] : [arg1, arg2]
    field  = :emma_repository
    result = obj&.try(field)&.to_s || obj&.try(:[], field)&.to_s
    # noinspection RubyMismatchedArgumentType
    if result&.to_sym == :emma
      url_repository(url) || result
    else
      result || url_repository(url)
    end
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
  def retrieval_link(label, url, css: '.artifact', **opt)
    opt.delete(:context) # In case this was invoked from a decorator.
    link  = download_link(label, url, **opt)
    error = html_span('', class: 'failure hidden')
    html_div(class: css_classes(css)) do
      link << error
    end
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
