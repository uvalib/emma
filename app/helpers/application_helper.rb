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
  include ParamsHelper
  include HtmlHelper
  include LayoutHelper
  include ImageHelper

  # The name of this application for display purposes.
  #
  # @type [String]
  #
  APP_NAME = I18n.t('emma.application.name')

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The name of this application for display purposes.
  #
  # @return [String]
  #
  def app_name
    APP_NAME
  end

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

end

__loading_end(__FILE__)
