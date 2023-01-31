# app/helpers/sessions_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods related to authentication.
#
module SessionsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for login session properties.
  #
  # @type [Hash{Symbol=>*}]
  #
  SESSIONS_CONFIG = I18n.t('emma.user.sessions', default: {}).deep_freeze

  # Default sign-in tooltip.
  #
  # @type [String]
  #
  SIGN_IN_TOOLTIP = SESSIONS_CONFIG.dig(:new, :tooltip)

  # Default sign-out tooltip.
  #
  # @type [String]
  #
  SIGN_OUT_TOOLTIP = SESSIONS_CONFIG.dig(:destroy, :tooltip)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sign in (via Bookshare) link.
  #
  # @param [String, nil]          label     Default: `#get_label(:new)`
  # @param [Symbol, String, nil]  provider  Default: :bookshare
  # @param [Boolean, String, nil] path      Default: `new_user_session_path`
  # @param [Hash]                 opt       Passed to #make_link.
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
    prepend_css!(opt, 'session-link', "#{provider}-login")
    make_link(label, path, **opt, title: SIGN_IN_TOOLTIP)
  end

  # Sign out link.
  #
  # @param [String]         label     Default: `#get_label(:destroy)`
  # @param [Symbol, String] provider  Default: :bookshare
  # @param [String, nil]    path      Default: `destroy_user_session_path`
  # @param [Hash]           opt       Passed to #make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Usage Notes
  # Use :path = *false* to disable without changing the appearance.
  #
  def sign_out_link(label: nil, provider: nil, path: nil, **opt)
    if path.is_a?(FalseClass)
      path = '#'
    elsif !path.is_a?(String)
      path_opt = {
        no_revoke: current_user&.administrator? || current_user&.test_user?
      }.compact_blank!
      path = destroy_user_session_path(**path_opt)
    end
    label        ||= get_sessions_label(:destroy, provider)
    provider     ||= :bookshare
    opt[:method] ||= :delete
    prepend_css!(opt, 'session-link', "#{provider}-logout")
    make_link(label, path, **opt, title: SIGN_OUT_TOOLTIP)
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
