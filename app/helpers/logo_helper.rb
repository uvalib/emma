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
  LOGO_TYPE = EmmaRepository::CONFIGURATION.dig(:_template, :logo).keys.freeze

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
    local = opt.extract!(:source, :name, :logo, :type, :alt)
    repo  = normalize_repository(local[:source] || item)
    name  = local[:name] || repository_name(repo)
    logo  = local[:logo] || repository_logo(repo, local[:type])
    alt   = local[:alt]  || ''
    if logo.present?
      opt[:role]  ||= 'presentation' if alt.blank?
      opt[:title] ||= repository_tooltip(item, name)
      prepend_css!(opt, css, repo)
      html_span(**opt) { image_tag(asset_path(logo), alt: alt) }
    else
      repository_source(repo, source: repo, name: name, **opt)
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
    local = opt.extract!(:source, :name)
    repo  = normalize_repository(local[:source] || item)
    name  = local[:name] || repository_name(repo)
    if name.present?
      opt[:title] ||= repository_tooltip(item, name)
      prepend_css!(opt, css, repo)
      html_div(**opt) { html_div(name) }
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
    repo = Upload.repository_value(src)
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
    logo = repo && EmmaRepository::ACTIVE.dig(repo.to_sym, :logo)
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
    key    = item.is_a?(Model) ? :item : :general
    name ||= repository_name(item) || config_text(:repository, key, :name)
    opt    = (key == :item) ? { an: indefinite_article(name) } : {}
    config_text(:repository, key, :tooltip, name: name, **opt)
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
