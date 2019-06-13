# app/controllers/concerns/user_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# UserConcern
#
module UserConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'UserConcern')
  end

  include SessionConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # OmniAuth endpoint console debugging output.
  #
  # @param [Array] args
  #
  # If args[0] is a Symbol it is treated as the calling method; otherwise the
  # calling method is derived from `#caller`.
  #
  def auth_debug(*args)
    method = (args.shift if args.first.is_a?(Symbol))
    method ||= caller(1,1).to_s.sub(/^[^`]*`(.*)'[^']*$/, '\1')
    part = []
    part << "OMNIAUTH #{method}"
    part << request&.method   if defined?(request)
    part << params.inspect    if defined?(params)
    part += args              if args.present?
    part += Array.wrap(yield) if block_given?
    __debug(part.join(' | '))
  end

  unless CONSOLE_DEBUGGING
    def auth_debug(*)
    end
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Update the current user with previously-acquired authentication data.
  #
  # @return [void]
  #
  def update_user
    data   = session['omniauth.auth']
    warden = request.env['warden']
    @user  = data && warden&.set_user(User.from_omniauth(data))
  end

end

__loading_end(__FILE__)
