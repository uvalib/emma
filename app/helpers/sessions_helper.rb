# app/helpers/sessions_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Authentication-related links.
#
module SessionsHelper

  def self.included(base)
    __included(base, '[SessionsHelper]')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sign in (via Bookshare) link.
  #
  # @param [String, nil]         label
  # @param [Symbol, String, nil] provider   Default: :bookshare
  # @param [Hash, nil]           opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def sign_in_link(label = nil, provider: nil, **opt)
    label    ||= get_label('new', provider)
    provider ||= :bookshare
    html_opt = {
      class:             "session-link #{provider}-login",
      'data-turbolinks': false,
    }
    html_opt.merge!(opt) if opt.present?
    link_to(label, new_user_session_path, html_opt)
  end

  # Sign out link.
  #
  # @param [String, nil]         label
  # @param [Symbol, String, nil] provider   Default: :bookshare
  # @param [Hash, nil]           opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def sign_out_link(label = nil, provider: nil, **opt)
    label    ||= get_label('destroy', provider)
    provider ||= :bookshare
    html_opt = {
      class:             "session-link #{provider}-logout",
      'data-turbolinks': false,
      method:            :delete,
    }
    html_opt.merge!(opt) if opt.present?
    link_to(label, destroy_user_session_path, html_opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get link label from the config/locales/en.yml.
  #
  # @param [String, Symbol]      action
  # @param [String, Symbol, nil] provider
  #
  # @return [String, nil]
  #
  def get_label(action, provider = nil)
    provider = provider.to_s.capitalize
    if provider.present?
      t("emma.user.omniauth_callbacks.#{action}.label", provider: provider)
    else
      t("emma.user.sessions.#{action}.label", default: action.to_s.capitalize)
    end
  end

end

__loading_end(__FILE__)
