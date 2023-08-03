# app/helpers/sessions_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods related to authentication.
#
module SessionsHelper

  include IdentityHelper

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

  # Link to sign-in options page.
  #
  # @param [String, nil]          label   Default: `#get_label(:new)`
  # @param [String, Boolean, nil] path    Default: `new_user_session_path`
  # @param [Hash]                 opt     Passed to #make_link except:
  #
  # @option opt [String, Symbol] :provider  Passed to #get_sessions_label.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # === Usage Notes
  # Use :path = *false* to disable without changing the appearance.
  #
  def sign_in_link(label: nil, path: nil, **opt)
    provider = opt.delete(:provider)
    label  ||= get_sessions_label(:new, provider)
    path     = '#' if path.is_a?(FalseClass)
    unless path.is_a?(String)
      path = (new_user_session_path unless path.is_a?(TrueClass))
    end
    prepend_css!(opt, "#{provider}-login") if provider
    prepend_css!(opt, 'session-link', 'session-login')
    make_link(label, path, **opt, title: SIGN_IN_TOOLTIP)
  end

  # Sign out link.
  #
  # @param [String]             label   Default: `#get_label(:destroy)`
  # @param [String, false, nil] path    Default: `destroy_user_session_path`
  # @param [Hash]               opt     Passed to #make_link except:
  #
  # @option opt [String, Symbol] :provider  Passed to #get_sessions_label.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # === Usage Notes
  # Use :path = *false* to disable without changing the appearance.
  #
  def sign_out_link(label: nil, path: nil, **opt)
    provider = opt.delete(:provider)
    label  ||= get_sessions_label(:destroy, provider)
    path     = '#' if path.is_a?(FalseClass)
    unless path.is_a?(String)
      no_revoke   = BS_AUTH
      no_revoke &&= administrator? || current_user&.test_user?
      path_opt    = no_revoke ? { no_revoke: true } : {}
      path        = destroy_user_session_path(**path_opt)
    end
    opt[:method] ||= :delete
    prepend_css!(opt, "#{provider}-logout") if provider
    prepend_css!(opt, 'session-link', 'session-logout')
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
    provider = provider.presence&.to_sym
    default  = [*opt.delete(:default), :"emma.user.sessions.#{action}.label"]
    case provider
      when nil    then key = default.shift.to_sym
      when :local then key = :"emma.user.sessions.#{action}.label"
      else             key = :"emma.user.omniauth_callbacks.#{action}.label"
    end
    opt[:provider] = OmniAuth::Utils.camelize(provider) if provider
    opt[:default]  = default
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
