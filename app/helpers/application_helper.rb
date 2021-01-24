# app/helpers/application_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common view helper methods.
#
module ApplicationHelper

  # @private
  def self.included(base)
    __included(base, '[ApplicationHelper]')
  end

  include Emma::Constants
  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Raw configuration entries for each controller that supplies content (i.e.,
  # those controllers with a subdirectory in app/view) plus 'en.emma.generic'.
  #
  # @type [Hash{Symbol=>*}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  CONTROLLER_CONFIGURATION =
    I18n.t('emma').select { |_, config|
      next unless config.is_a?(Hash)
      config[:index].is_a?(Hash) || config[:welcome].is_a?(Hash)
    }.deep_freeze

  # Configuration for application properties.
  #
  # @type [Hash{Symbol=>*}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  APP_CONFIG = I18n.t('emma.application', default: {}).deep_freeze

  # The controllers for the application.
  #
  # @type [Array<Symbol>]
  #
  APP_CONTROLLERS = CONTROLLER_CONFIGURATION.except(:generic).keys.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The name of this application for display purposes.
  #
  # @return [String]
  #
  def app_name
    APP_CONFIG[:name]
  end

  # Indicate whether a view template partial exists.
  #
  # @param [String] path
  # @param [Array]  prefixes          Default: [params[:controller]].
  #
  # @option prefixes.last [Hash]      Hash values to use in place of `params`.
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a description for the page from configuration.
  #
  # @param [String, Symbol, nil] controller   Default: `params[:controller]`
  # @param [String, Symbol, nil] action       Default: `params[:action]`
  # @param [Hash]                opt          Passed to #html_div
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def page_description(controller: nil, action: nil, **opt)
    text = page_text(controller: controller, action: action)
    html_div(text, prepend_css_classes!(opt, 'panel')) if text.present?
  end

  # Get the configured page description.
  #
  # @param [String, Symbol, nil] controller   Default: `params[:controller]`
  # @param [String, Symbol, nil] action       Default: `params[:action]`
  # @param [String, Symbol, nil] type         Optional type under action.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [String]
  # @return [nil]
  #
  def page_text(controller: nil, action: nil, type: nil)
    controller = (controller || params[:controller])&.to_sym
    action     = (action     || params[:action])&.to_sym
    entry = CONTROLLER_CONFIGURATION.dig(controller, action) || {}
    types = Array.wrap(type).compact.map(&:to_sym)
    types = %i[description text] if types.blank? || types == %i[description]
    # noinspection RubyYardReturnMatch
    types.find do |t|
      html  = "#{t}_html".to_sym
      plain = t.to_sym
      text  = entry[html]&.strip&.presence&.html_safe || entry[plain]&.strip
      return text if text.present?
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The "mailto:" link for the general e-mail contact.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def contact_email
    mail_to(CONTACT_EMAIL)
  end

end

__loading_end(__FILE__)
