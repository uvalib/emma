# test/mailers/previews/enrollment_mailer_preview.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Preview all emails at '/rails/mailers/enrollment_mailer'.
#
class EnrollmentMailerPreview < ActionMailer::Preview

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Preview '/rails/mailers/enrollment_mailer/request_email' using the latest
  # Enrollment by default or the specified Enrollment record if an :id
  # parameter is given.
  #
  def request_email
    id     = params[:id]
    item   = id ? Enrollment.find_by(id: id) : Enrollment.last
    item ||= fake_enrollment
    format = params[:part]&.include?('html') ? :html : :text
    EnrollmentMailer.with(item: item, format: format).request_email
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate a fake Enrollment if there is no record to use with the preview.
  #
  # @return [Enrollment]              Non-persisted instance.
  #
  def fake_enrollment
    user = {
      email:      'faker@fake.edu',
      first_name: 'Fake',
      last_name:  'User',
    }
    Enrollment.new(
      id:             1,
      short_name:     'XXX',
      long_name:      'Fake Organization Name',
      ip_domain:      '127.0.0.1',
      org_users:      [user],
      request_notes:  (1..3).map { "Request #{_1}" }.join("\n"),
      admin_notes:    (1..3).map { "Admin #{_1}"   }.join("\n"),
      created_at:     (now = DateTime.now),
      updated_at:     now,
    )
  end

end
