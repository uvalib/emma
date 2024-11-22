# test/mailers/enrollment_mailer_preview.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_mailer_test_case'

class EnrollmentMailerTest < ApplicationMailerTestCase

  setup do
    @item = enrollments(:example)
    @options = {
      to:   Emma::Project::ENROLL_EMAIL,
      from: @item.requesting_user[:email],
    }
  end

  # ===========================================================================
  # :section: Mailer tests
  # ===========================================================================

  test 'mailer enrollment - request_email' do
    validate_email(:enroll_request, **@options) do
      EnrollmentMailer.with(item: @item).request_email
    end
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'enrollment mailer test coverage' do
    skipped = []
    check_mailer_coverage EnrollmentMailer, except: skipped
  end

end
