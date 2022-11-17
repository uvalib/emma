# app/helpers/application_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common view helper methods.
#
module ApplicationHelper

  include Emma::Constants
  include Emma::Common

  include HtmlHelper
  include ConfigurationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Raw configuration entries for each controller that supplies content (i.e.,
  # those controllers with a subdirectory in app/view) plus 'emma.generic'
  # and distinct entries for each 'emma.user' Devise controller.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RailsI18nInspection, RubyArgCount
  #++
  CONTROLLER_CONFIGURATION =
    I18n.t('emma').select { |k, config|
      next true if k == :generic
      next unless config.is_a?(Hash)
      config.any? do |_, cfg|
        next unless cfg.is_a?(Hash)
        cfg[:_endpoint] || cfg.any? { |_, v| v.is_a?(Hash) && v[:_endpoint] }
      end
    }.then { |configs|
      configs = configs.transform_values { |config| config.except(:record) }
      devise  = configs[:user].select { |_, v| v.is_a?(Hash) && v.key?(:new) }
      user    = configs[:user].except(*devise.keys)
      devise.transform_keys! { |k| :"user_#{k}" }
      devise.transform_values! { |cfg| user.deep_dup.deep_merge!(cfg) }
      configs.merge!(user: user, **devise)
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
  # @note Currently unused.
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

  # The "mailto:" link for the general e-mail contact.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def contact_email
    mail_to(CONTACT_EMAIL)
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
