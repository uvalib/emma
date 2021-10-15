# app/helpers/logo_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the creation of repository logos.
#
module LogoHelper

  include HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Logo image variants for different purposes.
  #
  # @type [Array<Symbol>]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  LOGO_TYPE = I18n.t('emma.repository._template.logo').keys.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Make a logo for a repository source.
  #
  # @param [Model, Hash, String, Symbol, nil] item
  # @param [Hash] opt                 Passed to #html_span wrapper except for:
  #
  # @option opt [String] :source      Overrides derived value if present.
  # @option opt [String] :name        To be displayed instead of the source.
  # @option opt [String] :logo        Logo asset name.
  # @option opt [Symbol] :type        One of #LOGO_TYPE.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def repository_source_logo(item = nil, opt = nil)
    css_selector  = '.repository.logo'
    item, opt     = [nil, item] if item.is_a?(Hash) && opt.nil?
    opt, html_opt = partition_hash(opt, :source, :name, :logo, :type)
    repo = normalize_repository(opt[:source] || item)
    name = opt[:name] || repository_name(repo)
    logo = opt[:logo] || repository_logo(repo, opt[:type])
    if logo.present?
      html_opt[:title] ||= repository_tooltip(item, name)
      prepend_classes!(html_opt, css_selector, repo)
      html_span(html_opt) { image_tag(asset_path(logo), alt: "#{name} logo") }
    else
      repository_source(repo, html_opt.merge!(source: repo, name: name))
    end
  end

  # Make a textual logo for a repository source.
  #
  # @param [Model, Hash, String, Symbol, nil] item
  # @param [Hash] opt                 Passed to #html_div except for:
  #
  # @option opt [String] :source      Overrides derived value if present.
  # @option opt [String] :name        To be displayed instead of the source.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def repository_source(item, opt = nil)
    css_selector  = '.repository.name'
    opt, html_opt = partition_hash(opt, :source, :name)
    repo = normalize_repository(opt[:source] || item)
    name = opt[:name] || repository_name(repo)
    if name.present?
      html_opt[:title] ||= repository_tooltip(item, name)
      prepend_classes!(html_opt, css_selector, repo)
      html_div(html_opt) { html_div(name) }
    else
      ''.html_safe
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # normalize_repository
  #
  # @param [Model, Hash, String, Symbol, nil] src
  #
  # @return [String]                  One of EmmaRepository#values.
  # @return [nil]                     If *src* did not indicate a repository.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def normalize_repository(src)
    return EmmaRepository.default if src.blank?
    src  = src.to_s               if src.is_a?(Symbol)
    src  = src.squish             if src.is_a?(String)
    repo = Upload.repository_of(src)
    return repo if repo && EmmaRepository.valid?(repo) || !src.is_a?(String)
    # Attempt a reverse lookup by repository name.
    EmmaRepository.pairs.first { |_repo, name| src.casecmp?(name) }&.first
  end

  # repository_name
  #
  # @param [Model, Hash, String, Symbol, nil] src
  #
  # @return [String]                  The name of the associated repository.
  # @return [nil]                     If *src* did not indicate a repository.
  #
  def repository_name(src)
    repo = normalize_repository(src)
    EmmaRepository.pairs[repo] if repo
  end

  # repository_logo
  #
  # @param [Model, Hash, String, Symbol, nil] src
  # @param [Symbol, nil]                      type  One of #LOGO_TYPE.
  #
  # @return [String]                  The logo of the associated repository.
  # @return [nil]                     If *src* did not indicate a repository.
  #
  def repository_logo(src, type = nil)
    repo = normalize_repository(src)
    logo = repo && Api::Common::REPOSITORY.dig(repo.to_sym, :logo)
    logo = logo[type&.to_sym] || logo[LOGO_TYPE.first] if logo.is_a?(Hash)
    # noinspection RubyMismatchedReturnType
    logo
  end

  # repository_tooltip
  #
  # @param [Model, Hash, String, Symbol, nil] item
  # @param [String]                           name
  #
  # @return [String]
  #
  def repository_tooltip(item, name = nil)
    name ||= repository_name(item)
    if item.is_a?(Model)
      name ||= 'external' # TODO: I18n
      a = name.match?(/^[aeiou]/i) ? 'an' : 'a'
      "This is #{a} #{name} repository item" # TODO: I18n
    else
      name ||= 'an external repository' # TODO: I18n
      "From #{name}" # TODO: I18n
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
