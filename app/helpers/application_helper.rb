# app/helpers/application_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common view helper methods.
#
module ApplicationHelper

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
  CONTROLLER_CONFIGURATION =
    config_all[:page].map { |ctrlr, config|
      next if ctrlr.start_with?('_')
      action = config[:action].reject { |k, _| k.start_with?('_') }
      [ctrlr, config.merge(action: action)]
    }.compact.to_h.deep_freeze

  # Configuration for application properties.
  #
  # @type [Hash]
  #
  APP_CONFIG = config_section(:application).deep_freeze

  # The controllers for the application.
  #
  # @type [Array<Symbol>]
  #
  APP_CONTROLLERS = CONTROLLER_CONFIGURATION.keys.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The name of this application for display purposes.
  #
  # @return [String]
  #
  # @note Currently unused.
  # :nocov:
  def app_name
    APP_CONFIG[:name]
  end
  # :nocov:

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

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
