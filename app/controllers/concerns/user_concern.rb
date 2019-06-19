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
