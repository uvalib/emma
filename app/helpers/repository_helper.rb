# app/helpers/repository_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting variations for partner repositories.
#
module RepositoryHelper

  include LinkHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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

  # Report the partner repository associated with the given URL.
  #
  # @param [String, nil] url
  #
  # @return [String]                  One of EmmaRepository#values.
  # @return [nil]                     If not associated with any repository.
  #
  def url_repository(url)
    return unless url.present?
    case
      when emma_link?(url) then :emma
      when ia_link?(url)   then :internetArchive
      else                      Log.warn { "#{__method__}: #{url.inspect}" }
    end&.to_s
  end

  # Report the partner repository as indicated by the given parameter(s).
  #
  # To account for the handful of "EMMA" items that are actually Bookshare
  # items from the "EMMA collection", if both a String (URL) and Model/Hash are
  # given, change the reported repository based on the nature of the URL.
  #
  # @param [String, Model, Hash, nil] url
  # @param [Model, Hash, nil]         obj     Default: #object.
  # @param [Symbol]                   field
  #
  # @return [String]                  One of EmmaRepository#values.
  # @return [nil]                     If not associated with any repository.
  #
  def repository_for(url, obj = nil, field: :emma_repository)
    url, obj = [nil, url] if url && !url.is_a?(String)
    # noinspection RubyMismatchedArgumentType
    repo = url_repository(url) and return repo
    (obj ||= object) && (obj.try(field) || obj.try(:[], field))&.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce a link to retrieve an EMMA file.
  #
  # @param [String] label
  # @param [String] url
  # @param [Hash]   opt               Passed to #retrieval_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emma_retrieval_link(label, url, **opt)
    url = url.sub(%r{localhost:\d+}, 'localhost') if not_deployed?
    retrieval_link(label, url, **opt)
  end

  # Produce a link to retrieve an Internet Archive file.
  #
  # @param [String] label
  # @param [String] url
  # @param [Hash]   opt               Passed to #retrieval_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # === Implementation Notes
  # Encrypted DAISY files are handled differently; for an explanation:
  # @see IaDownloadConcern#ia_download_response
  #
  def ia_retrieval_link(label, url, **opt)
    direct = IA_DIRECT_LINK_PATTERNS.any? { |pattern| url.match?(pattern) }
    url    = retrieval_path(url: url) unless direct
    retrieval_link(label, url, **opt)
  end

  # Produce a link to retrieve an ACE file.
  #
  # @param [String] label
  # @param [String] url
  # @param [Hash]   opt               Passed to #ia_retrieval_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def ace_retrieval_link(label, url, **opt)
    ia_retrieval_link(label, url, **opt)
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
