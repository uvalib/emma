# app/helpers/sessions_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Authentication-related methods.
#
module SessionsHelper

  def self.included(base)
    __included(base, '[SessionsHelper]')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default sign-in tooltip.
  #
  # @type [String]
  #
  SIGN_IN_TOOLTIP = I18n.t('emma.user.sessions.new.tooltip').freeze

  # Default sign-out tooltip.
  #
  # @type [String]
  #
  SIGN_OUT_TOOLTIP = I18n.t('emma.user.sessions.destroy.tooltip').freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sign in (via Bookshare) link.
  #
  # @param [String, nil]          label     Default: `#get_label(:new)`
  # @param [Symbol, String, nil]  provider  Default: :bookshare
  # @param [Boolean, String, nil] path      Default: `new_user_session_path`
  # @param [Hash]                 opt       Passed to #link_to.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Usage Notes
  # Use :path = *false* to disable without changing the appearance.
  #
  def sign_in_link(label: nil, provider: nil, path: nil, **opt)
    path       = '#' if path.is_a?(FalseClass)
    path       = nil if path.is_a?(TrueClass)
    path     ||= new_user_session_path
    label    ||= get_sessions_label(:new, provider)
    provider ||= :bookshare
    html_opt = {
      class:             "session-link #{provider}-login",
      title:             SIGN_IN_TOOLTIP,
      'data-turbolinks': false,
    }
    merge_html_options!(html_opt, opt)
    link_to(label, path, html_opt)
  end

  # Sign out link.
  #
  # @param [String]         label     Default: `#get_label(:destroy)`
  # @param [Symbol, String] provider  Default: :bookshare
  # @param [String, nil]    path      Default: `destroy_user_session_path`
  # @param [Hash]           opt       Passed to #link_to.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Usage Notes
  # Use :path = *false* to disable without changing the appearance.
  #
  def sign_out_link(label: nil, provider: nil, path: nil, **opt)
    label    ||= get_sessions_label(:destroy, provider)
    provider ||= :bookshare
    unless path.is_a?(String)
      path = path.is_a?(FalseClass) ? '#' : destroy_user_session_path
    end
    html_opt = {
      class:             "session-link #{provider}-logout",
      title:             SIGN_OUT_TOOLTIP,
      'data-turbolinks': false,
      method:            :delete,
    }
    merge_html_options!(html_opt, opt)
    link_to(label, path, html_opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get link label from the config/locales/controllers/user.en.yml.
  #
  # @param [String, Symbol]      action
  # @param [String, Symbol, nil] provider
  # @param [Hash]                opt        Passed to TranslationHelper#t.
  #
  # @return [String]
  #
  def get_sessions_label(action, provider = nil, **opt)
    default = [:"emma.user.sessions.#{action}.label", *opt[:default]]
    if (provider ||= opt[:provider])
      opt[:provider] = OmniAuth::Utils.camelize(provider)
      key = :"emma.user.omniauth_callbacks.#{action}.label"
    else
      key = default.shift
    end
    opt[:default] = default
    t(key, **opt)
  end

end

__loading_end(__FILE__)
