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
  # @param [Hash, nil] p              Default: `#request_parameters`
  #
  def rendering_html?(p = nil)
    p ||= request_parameters
    fmt = p[:format].to_s.downcase
    (fmt == 'html') || (respond_to?(:request) && request.format.html?)
  end

  # Indicate whether the ultimate target format is something other than HTML.
  #
  # @param [Hash, nil] p              Default: `#request_parameters`
  #
  def rendering_non_html?(p = nil)
    !rendering_html?(p)
  end

  # Indicate whether the ultimate target format is JSON.
  #
  # @param [Hash, nil] p              Default: `#request_parameters`
  #
  def rendering_json?(p = nil)
    p ||= request_parameters
    fmt = p[:format].to_s.downcase
    (fmt == 'json') || (respond_to?(:request) && request.format.json?)
  end

  # Indicate whether the ultimate target format is XML.
  #
  # @param [Hash, nil] p              Default: `#request_parameters`
  #
  def rendering_xml?(p = nil)
    p ||= request_parameters
    fmt = p[:format].to_s.downcase
    (fmt == 'xml') || (respond_to?(:request) && request.format.xml?)
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
