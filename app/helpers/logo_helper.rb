# app/helpers/logo_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

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
  # @param [Search::Api::Record, String, Symbol] item
  # @param [Hash] opt                 Passed to #image_tag except for:
  #
  # @option opt [String] :source      Overrides :src if present.
  # @option opt [String] :name        To be displayed instead of the source.
  # @option opt [String] :logo        Logo asset name.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def repository_source_logo(item, opt = nil)
    opt, html_opt = partition_options(opt, :source, :name, :logo)
    src  = normalize_repository(opt[:source] || item || DEFAULT_REPO)
    name = opt[:name] || repository_name(src)
    logo = REPOSITORY_LOGO[src]
    if logo.present?
      prepend_css_classes!(html_opt, 'repository', 'logo', src)
      html_opt[:title] ||= repository_tooltip(item, name)
      # noinspection RubyYardReturnMatch
      image_tag(asset_path(logo), html_opt)
    else
      repository_source(src, html_opt.merge!(source: src, name: name))
    end
  end

  # Make a textual logo for a repository source.
  #
  # @param [Search::Api::Record, String, Symbol] item
  # @param [Hash] opt                 Passed to #html_div except for:
  #
  # @option opt [String] :source      Overrides :src if present.
  # @option opt [String] :name        To be displayed instead of the source.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def repository_source(item, opt = nil)
    opt, html_opt = partition_options(opt, :source, :name)
    src  = normalize_repository(opt[:source] || item || DEFAULT_REPO)
    name = opt[:name] || repository_name(src)
    if name.present?
      prepend_css_classes!(html_opt, 'repository', 'name', src)
      html_opt[:title] ||= repository_tooltip(item, name)
      html_div(html_div(name), html_opt)
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
  # @param [Search::Api::Record, String, Symbol, nil] src
  #
  # @return [String]
  # @return [nil]
  #
  def normalize_repository(src)
    src = src.emma_repository if src.respond_to?(:emma_repository)
    src = src.to_s
    # noinspection RubyYardReturnMatch
    src if EmmaRepository.values.include?(src)
  end

  # repository_name
  #
  # @param [Search::Api::Record, String, Symbol, nil] src
  #
  # @return [String]
  # @return [nil]
  #
  def repository_name(src)
    src = src.emma_repository if src.respond_to?(:emma_repository)
    src = src.to_s
    # noinspection RubyYardReturnMatch
    (src == DEFAULT_REPO.to_s) ? src.upcase : src.titleize if src.present?
  end

  # repository_tooltip
  #
  # @param [Search::Api::Record, String, Symbol, nil] item
  # @param [String]                                   name
  #
  # @return [String]
  #
  def repository_tooltip(item, name = nil)
    name ||= repository_name(item)
    if item.is_a?(Model)
      a = name.start_with?(/[aeiou]/i) ? 'an' : 'a'
      "This is #{a} #{name} repository item" # TODO: I18n
    else
      "From #{name}" # TODO: I18n
    end
  end

end

__loading_end(__FILE__)
