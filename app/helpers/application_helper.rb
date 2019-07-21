# app/helpers/application_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common helper methods.
#
module ApplicationHelper

  def self.included(base)
    __included(base, '[ApplicationHelper]')
  end

  include Emma::Constants
  include GenericHelper
  include I18nHelper
  include ParamsHelper
  include HtmlHelper
  include HeadHelper
  include LayoutHelper
  include ImageHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The name of this application for display purposes.
  #
  # @type [String]
  #
  APP_NAME = I18n.t('emma.application.name').freeze

  # The name of this application for display purposes.
  #
  # @return [String]
  #
  def app_name
    APP_NAME
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the ultimate target format is HTML.
  #
  # @param [Hash, nil] opt
  #
  def rendering_html?(opt)
    ((opt[:format].to_s.downcase == 'html') if opt.is_a?(Hash)) ||
      (request.format.html? if defined?(request))
  end

  # Indicate whether the ultimate target format is something other than HTML.
  #
  # @param [Hash, nil] opt
  #
  def rendering_non_html?(opt)
    !rendering_html?(opt)
  end

  # Indicate whether the ultimate target format is JSON.
  #
  # @param [Hash, nil] opt
  #
  def rendering_json?(opt)
    ((opt[:format].to_s.downcase == 'json') if opt.is_a?(Hash)) ||
      (request.format.json? if defined?(request))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether a view template partial exists.
  #
  # @param [String] path
  # @param [Array]  prefixes          Default: [params[:controller]].
  #
  # @option prefixes.last [Hash]      Hash values to use in place of `#params`.
  #
  def partial_exists?(path, *prefixes)
    return if path.blank?
    p = (prefixes.pop if prefixes.last.is_a?(Hash))
    if prefixes.blank? && !path.include?('/')
      p ||= params
      prefixes << p[:controller]
    end
    lookup_context.template_exists?(path, prefixes, true)
  end

end

__loading_end(__FILE__)
