# test/mailers/devise_mailer_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_mailer_test_case'

class DeviseMailerTest < ApplicationMailerTestCase

  setup do
    @user = find_user(:test_dso_1)
  end

  # ===========================================================================
  # :section: Mailer tests
  # ===========================================================================

  test 'mailer devise - reset_password_instructions' do
    email = Devise::Mailer.reset_password_instructions(@user, 'faketoken')
    assert_emails(1) { email.deliver_later }
    opt = {
      to:       @user.email,
      from:     Emma::Project::HELP_EMAIL,
      subject:  I18n.t('devise.mailer.reset_password_instructions.subject'),
      heading:  'change your password',
    }
    check_email(email, **opt)
  end

end
