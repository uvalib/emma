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

  # Indicate whether the given URL is an EMMA link.
  #
  # @param [String, nil] url
  #
  def emma_link?(url)
    url.to_s.strip.match?(%r{^https?://emma[^/]*\.virginia\.edu/}i)
  end

  # Indicate whether the given URL is an Internet Archive link.
  #
  # ACE/ScholarsPortal items are hosted by Internet Archive with download links
  # which are indistinguishable.
  #
  # @param [String, nil] url
  #
  def ia_link?(url)
    url.to_s.strip.match?(%r{^https?://([^./]+\.)*archive\.org/}i)
  end

  # Indicate whether the given URL is an OpenAlex link.
  #
  # @param [String, nil] url
  #
  def oa_link?(url)
    url.to_s.strip.match?(%r{^https?://([^./]+\.)*openalex\.org/}i)
  end

  # Indicate whether the given URL is an EMMA publisher collection item link.
  #
  # @param [String, nil] url
  #
  def bv_link?(url)
    url.to_s.strip.match?(%r{^https?://[^/]*bibliovault[^/]*/}i)
  end

  # Report the partner repository associated with the given URL.
  #
  # @param [String, nil] url
  # @param [Boolean]     warn
  #
  # @return [Symbol]                  From one of EmmaRepository#values.
  # @return [nil]                     Associated repo could not be determined.
  #
  def url_repository(url, warn: false)
    case
      when url.blank?      then nil
      when emma_link?(url) then :emma
      when oa_link?(url)   then :openAlex
      when ia_link?(url)   then :internetArchive
      when bv_link?(url)   then :biblioVault # :bibliovault_ump
      when warn            then Log.warn { "#{__method__}: #{url.inspect}" }
    end
  end

  # Report the partner repository as indicated by the given parameter(s).
  #
  # To account for the handful of "EMMA" items that are actually Bookshare
  # items from the "EMMA collection", if both a String (URL) and Model/Hash are
  # given, change the reported repository based on the nature of the URL.
  #
  # @param [String, Model, Hash, nil] url
  # @param [Model, Hash, nil]         obj
  # @param [Symbol]                   field
  #
  # @return [Symbol]                  From one of EmmaRepository#values.
  # @return [nil]                     Associated repo could not be determined.
  #
  def repository_for(url, obj = nil, field: :emma_repository)
    url, obj = [nil, url] if url && !url.is_a?(String)
    (obj&.try(field) || obj&.try(:[], field) || url_repository(url))&.to_sym
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the term for the indicated repository needed for
  # "en.emma.term.search.source.link_tooltip".
  #
  # @param [any, nil] repo            EmmaRepository, String, Symbol
  #
  # @return [String]
  #
  def record_src(repo)
    repository_config_value(__method__, repo)
  end

  # Return the term for the indicated repository needed for
  # "en.emma.term.search.source.retrieval_tip".
  #
  # @param [any, nil] repo            EmmaRepository, String, Symbol
  #
  # @return [String]
  #
  def download_src(repo)
    repository_config_value(__method__, repo)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get a value from "en.emma.repository.#(repo)" or the fallback value from
  # "en.emma.repository._template".
  #
  # @note "en.emma.repository._template.#(key)" is expected to be non-nil.
  #
  # @param [Symbol]   key
  # @param [any, nil] repo            EmmaRepository, String, Symbol
  #
  # @return [String]
  #
  def repository_config_value(key, repo = nil)
    cfg  = EmmaRepository::CONFIGURATION
    repo = repo.value if repo.is_a?(EmmaRepository)
    repo = (repo.to_sym.presence if repo.is_a?(String) || repo.is_a?(Symbol))
    repo && cfg.dig(repo, key) || cfg.dig(:_template, key)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce a link to retrieve an EMMA file.
  #
  # @param [String] url
  # @param [Hash]   opt               Passed to #retrieval_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emma_retrieval_link(url, **opt)
    url = url.sub(%r{localhost:\d+}, 'localhost') if not_deployed?
    retrieval_link(url, **opt)
  end

  # Produce a link to retrieve an Internet Archive file.
  #
  # @param [String] url
  # @param [Hash]   opt               Passed to #retrieval_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def ia_retrieval_link(url, **opt)
    retrieval_link(url, **opt)
  end

  # Produce a link to retrieve an ACE file.
  #
  # @param [String] url
  # @param [Hash]   opt               Passed to #ia_retrieval_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def ace_retrieval_link(url, **opt)
    ia_retrieval_link(url, **opt)
  end

  # Produce a link to retrieve an OpenAlex file.
  #
  # @note OpenAlex only has direct download of PDF files.
  #
  # @param [String] url
  # @param [Hash]   opt               Passed to #retrieval_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def oa_retrieval_link(url, **opt)
    retrieval_link(url, **opt)
  end

  # Produce a link to retrieve a file from an EMMA publisher collection.
  #
  # @param [String] url
  # @param [Hash]   opt               Passed to #retrieval_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bv_retrieval_link(url, **opt)
    file = url.split('/').last
    url  = '/retrieval?url=%s' % url_escape(url)
    retrieval_link(url, file: file, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Produce a link to retrieve a content file.
  #
  # @param [String] url
  # @param [Hash]   opt               Passed to LinkHelper#download_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def retrieval_link(url, css: '.retrieval', **opt)
    link  = download_link(url, **opt)
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
