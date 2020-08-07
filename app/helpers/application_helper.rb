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
  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The name of this application for display purposes.
  #
  # @type [String]
  #
  APP_NAME = I18n.t('emma.application.name').freeze

  # The controllers for the application.
  #
  # @type [Array<Symbol>]
  #
  APP_CONTROLLERS = I18n.t('emma.application.controllers').map(&:to_sym).freeze

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
