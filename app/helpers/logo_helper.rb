# app/helpers/logo_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'search'

# Repository logos.
#
module LogoHelper

  def self.included(base)
    __included(base, '[LogoHelper]')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  DEFAULT_REPO = :emma

  # Generic source repository values.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  REPOSITORY_TEMPLATE =
    I18n.t('emma.source._template', default: {}).deep_freeze

  # Repository logo image assets.
  #
  # @type [Hash{String=>String}]
  #
  REPOSITORY_LOGO =
    Search::REPOSITORY.transform_values { |entry| entry[:logo] }
      .stringify_keys
      .deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Make a logo for a repository source.
  #
  # @param [String, Symbol, nil] src
  # @param [Hash]                opt    Passed to #content_tag except for:
  #
  # @option opt [String] :source
  # @option opt [String] :name          To be displayed instead of the source.
  # @option opt [String] :logo          Logo asset name.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def repository_source_logo(src, **opt)
    opt, html_opt = partition_options(opt, :source, :name, :logo)
    src  = normalize_repository(opt[:source] || src || DEFAULT_REPO)
    name = opt[:name] || repository_name(src)
    logo = REPOSITORY_LOGO[src]
    if logo.present?
      prepend_css_classes!(html_opt, 'repository', 'logo', src)
      html_opt[:title] ||= "From #{name}" # TODO: I18n
      # noinspection RubyYardReturnMatch
      image_tag(asset_path(logo), html_opt)
    else
      repository_source(src, **html_opt.merge!(source: src, name: name))
    end
  end

  # Make a textual logo for a repository source.
  #
  # @param [String, Symbol, nil] src
  # @param [Hash]                opt    Passed to #content_tag except for:
  #
  # @option opt [String] :source
  # @option opt [String] :name          To be displayed instead of the source.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def repository_source(src, **opt)
    opt, html_opt = partition_options(opt, :source, :name)
    src  = normalize_repository(opt[:source] || src || DEFAULT_REPO)
    name = opt[:name] || repository_name(src)
    if name.present?
      prepend_css_classes!(html_opt, 'repository', 'name', src)
      html_opt[:title] ||= "From #{name}" # TODO: I18n
      content_tag(:div, content_tag(:div, name), html_opt)
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
  # @param [String, Symbol, nil] src
  #
  # @return [String]
  # @return [nil]
  #
  def normalize_repository(src)
    src = src.to_s
    # noinspection RubyYardReturnMatch
    src if EmmaRepository.values.include?(src)
  end

  # repository_name
  #
  # @param [String, Symbol, nil] src
  #
  # @return [String]
  # @return [nil]
  #
  def repository_name(src)
    src = src.to_s
    # noinspection RubyYardReturnMatch
    (src == DEFAULT_REPO.to_s) ? src.upcase : src.titleize if src.present?
  end

end

__loading_end(__FILE__)
