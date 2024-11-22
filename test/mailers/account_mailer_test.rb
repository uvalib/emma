# test/mailers/account_mailer_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_mailer_test_case'

class AccountMailerTest < ApplicationMailerTestCase

  setup do
    @user = find_user(:test_dso_1)
    @options = {
      to:   @user.email,
      from: Emma::Project::CONTACT_EMAIL,
    }
  end

  # ===========================================================================
  # :section: Mailer tests
  # ===========================================================================

  test 'mailer account - new_user_email' do
    validate_email(:new_user, **@options) do
      AccountMailer.with(item: @user).new_user_email
    end
  end

  test 'mailer account - new_man_email' do
    validate_email(:new_man, **@options) do
      AccountMailer.with(item: @user).new_man_email
    end
  end

  test 'mailer account - new_org_email' do
    validate_email(:new_org, **@options) do
      AccountMailer.with(item: @user).new_org_email
    end
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'account mailer test coverage' do
    skipped = []
    check_mailer_coverage AccountMailer, except: skipped
  end

end
