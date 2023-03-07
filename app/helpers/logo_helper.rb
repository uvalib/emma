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
  LOGO_TYPE = I18n.t('emma.repository._template.logo').keys.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Make a logo for a repository source.
  #
  # For accessibility purposes, logos are treated as decorative unless a
  # non-blank `opt[:alt]` is provided.
  #
  # @param [Model, Hash, String, Symbol, nil] item
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #html_span wrapper except for:
  #
  # @option opt [String] :source      Overrides derived value if present.
  # @option opt [String] :name        To be displayed instead of the source.
  # @option opt [String] :logo        Logo asset name.
  # @option opt [Symbol] :type        One of #LOGO_TYPE.
  # @option opt [String] :alt         Image text for screen-reader visibility.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def repository_source_logo(item = nil, css: '.repository.logo', **opt)
    html_opt = remainder_hash!(opt, :source, :name, :logo, :type, :alt)
    repo = normalize_repository(opt[:source] || item)
    name = opt[:name] || repository_name(repo)
    logo = opt[:logo] || repository_logo(repo, opt[:type])
    alt  = opt[:alt]  || ''
    if logo.present?
      html_opt[:role]  ||= 'presentation' if alt.blank?
      html_opt[:title] ||= repository_tooltip(item, name)
      prepend_css!(html_opt, css, repo)
      html_span(html_opt) { image_tag(asset_path(logo), alt: alt) }
    else
      html_opt.merge!(source: repo, name: name)
      repository_source(repo, **html_opt)
    end
  end

  # Make a textual logo for a repository source.
  #
  # @param [Model, Hash, String, Symbol, nil] item
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #html_div except for:
  #
  # @option opt [String] :source      Overrides derived value if present.
  # @option opt [String] :name        To be displayed instead of the source.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def repository_source(item, css: '.repository.name', **opt)
    opt, html_opt = partition_hash(opt, :source, :name)
    repo = normalize_repository(opt[:source] || item)
    name = opt[:name] || repository_name(repo)
    if name.present?
      html_opt[:title] ||= repository_tooltip(item, name)
      prepend_css!(html_opt, css, repo)
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
