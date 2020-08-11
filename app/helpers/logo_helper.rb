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

  # Make a logo for a repository source.
  #
  # @param [Search::Api::Record, String, Symbol, nil] item
  # @param [Hash] opt                 Passed to #html_span wrapper except for:
  #
  # @option opt [String] :source      Overrides derived value if present.
  # @option opt [String] :name        To be displayed instead of the source.
  # @option opt [String] :logo        Logo asset name.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def repository_source_logo(item = nil, opt = nil)
    opt, html_opt = partition_options(opt, :source, :name, :logo)
    repo = normalize_repository(opt[:source] || item)
    name = opt[:name] || repository_name(repo)
    logo = Api::Common::REPOSITORY.dig(repo, :logo)
    if logo.present?
      prepend_css_classes!(html_opt, 'repository', 'logo', repo)
      html_opt[:title] ||= repository_tooltip(item, name)
      html_span(html_opt) { image_tag(asset_path(logo), alt: "#{name} logo") }
    else
      # noinspection RubyYardParamTypeMatch
      repository_source(repo, html_opt.merge!(source: repo, name: name))
    end
  end

  # Make a textual logo for a repository source.
  #
  # @param [Search::Api::Record, String, Symbol] item
  # @param [Hash] opt                 Passed to #html_div except for:
  #
  # @option opt [String] :source      Overrides derived value if present.
  # @option opt [String] :name        To be displayed instead of the source.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def repository_source(item, opt = nil)
    opt, html_opt = partition_options(opt, :source, :name)
    repo = normalize_repository(opt[:source] || item)
    name = opt[:name] || repository_name(repo)
    if name.present?
      prepend_css_classes!(html_opt, 'repository', 'name', repo)
      html_opt[:title] ||= repository_tooltip(item, name)
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
  # @param [Search::Api::Record, String, Symbol, nil] src
  #
  # @return [Symbol]                  One of EmmaRepository#values.
  # @return [nil]                     If *src* did not indicate a repository.
  #
  #--
  # noinspection RubyResolve, RubyNilAnalysis
  #++
  def normalize_repository(src)
    return Api::Common::DEFAULT_REPOSITORY if src.blank?
    src = src.emma_repository              if src.respond_to?(:emma_repository)
    src = src.to_s.squish
    Api::Common::REPOSITORY.find do |repo, config|
      return repo if (repo.to_s == src) || src.casecmp(config[:name]).zero?
    end
  end

  # repository_name
  #
  # @param [Search::Api::Record, String, Symbol, nil] src
  #
  # @return [String]                  The name of the associated repository.
  # @return [nil]                     If *src* did not indicate a repository.
  #
  def repository_name(src)
    repo = normalize_repository(src)
    Api::Common::REPOSITORY.dig(repo, :name)
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
      name ||= 'external' # TODO: I18n
      a = name.match?(/^[aeiou]/i) ? 'an' : 'a'
      "This is #{a} #{name} repository item" # TODO: I18n
    else
      name ||= 'an external repository' # TODO: I18n
      "From #{name}" # TODO: I18n
    end
  end

end

__loading_end(__FILE__)
