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

  # Default sign-in tooltip.
  #
  # @type [String]
  #
  SIGN_IN_TOOLTIP = config_page(:user_sessions, :new, :tooltip).freeze

  # Default sign-out tooltip.
  #
  # @type [String]
  #
  SIGN_OUT_TOOLTIP = config_page(:user_sessions, :destroy, :tooltip).freeze

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
    make_link(path, label, **opt, title: SIGN_IN_TOOLTIP)
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
    path   ||= destroy_user_session_path
    prepend_css!(opt, "#{provider}-logout") if provider
    prepend_css!(opt, 'session-link', 'session-logout')
    make_link(path, label, method: :delete, **opt, title: SIGN_OUT_TOOLTIP)
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
    cfg_path = ->(ctrlr) { :"emma.page.#{ctrlr}.action.#{action}.label" }
    default  = [*opt.delete(:default), cfg_path.(:user_sessions)]
    case provider&.to_sym
      when nil    then key = default.shift.to_sym
      when :local then key = cfg_path.(:user_sessions)
      else             key = cfg_path.(:user_omniauth_callbacks)
    end
    opt[:provider] = OmniAuth::Utils.camelize(provider) if provider
    config_entry(key, default: default, **opt) || action.to_s
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
