# test/mailers/previews/account_mailer_preview.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Preview all emails at '/rails/mailers/account_mailer'.
#
class AccountMailerPreview < ActionMailer::Preview

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Preview '/rails/mailers/account_mailer/new_user_email' using a fake user by
  # default or the specified User record if an :id parameter is given.
  #
  def new_user_email
    id     = params[:id]
    item   = id ? User.find_by(id: id) : fake_user
    format = params[:part]&.include?('html') ? :html : :text
    AccountMailer.with(item: item, format: format).new_user_email
  end

  # Preview '/rails/mailers/account_mailer/new_org_email' using a fake user by
  # default or the specified User record if an :id parameter is given.
  #
  def new_org_email
    id     = params[:id]
    item   = id ? User.find_by(id: id) : fake_user
    format = params[:part]&.include?('html') ? :html : :text
    AccountMailer.with(item: item, format: format).new_org_email
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate a fake User if there is no record to use with the preview.
  #
  # @return [User]                    Non-persisted instance.
  #
  def fake_user
    User.new(
      id:           1,
      email:        'faker@fake.edu',
      first_name:   'Fake',
      last_name:    'User',
      phone:        '(500) 555-1212',
      address:      'City, ST 12345',
      status:       :active,
      role:         :member,
      created_at:   (now = DateTime.now),
      updated_at:   now,
      status_date:  now,
    )
  end

end
