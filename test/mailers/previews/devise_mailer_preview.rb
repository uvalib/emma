# test/mailers/previews/devise_mailer_preview.rb
#
# frozen_string_literal: true
# warn_indent:           true

class DeviseMailerPreview < ActionMailer::Preview

  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(User.first, 'faketoken')
  end

end
