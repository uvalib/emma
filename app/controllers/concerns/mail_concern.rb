# app/controllers/concerns/mail_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for generating emails.
#
module MailConcern

  extend ActiveSupport::Concern

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Set when the current record operation has assigned a Manager to an
  # organization that had none (because the Org record had been created by
  # an Administrator with an empty :contact field).
  #
  # @type [Boolean, nil]
  #
  attr_reader :new_org_man

  # Set when a new Manager user is created (outside the context of creating a
  # new organization) or when the role of an existing user is set to Manager.
  #
  # @type [Boolean, nil]
  #
  attr_reader :new_man

  # Set when the current record operation has created an Administrator user or
  # converted an organization member user into an Administrator.
  #
  # @type [Boolean, nil]
  #
  attr_reader :new_admin

  # Set when a new non-Administrator user is created.
  #
  # @type [Boolean, nil]
  #
  attr_reader :new_user

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether emails should be generated.
  #
  def send_welcome_email?
    mail_parameter?(:welcome)
  end

  # Indicate whether #generate_new_user_email should be run for a new user.
  #
  def new_user_email?
    new_user.present? && send_welcome_email?
  end

  # Send a welcome email to a new user.
  #
  # @param [User] user
  # @param [Hash] opt
  #
  # @return [void]
  #
  # @see AccountMailer#new_user_email
  #
  def generate_new_user_email(user, **opt)
    prm = url_parameters.slice(*ApplicationMailer::MAIL_OPT).except!(:to)
    opt = prm.merge!(opt, item: user)
    AccountMailer.with(opt).new_user_email.deliver_later
  end

  # Indicate whether #generate_new_man_email should be run for a new manager.
  #
  def new_man_email?
    new_man.present? && send_welcome_email?
  end

  # Send a welcome email to a new manager.
  #
  # @param [User] user
  # @param [Hash] opt
  #
  # @return [void]
  #
  def generate_new_man_email(user, **opt)
    prm = url_parameters.slice(*ApplicationMailer::MAIL_OPT).except!(:to)
    opt = prm.merge!(opt, item: user)
    AccountMailer.with(opt).new_man_email.deliver_later
  end

  # Indicate whether #generate_new_org_email should be run for a user that
  # has been modified to be the Manager of a new organization.
  #
  def new_org_email?
    new_org_man.present? && send_welcome_email?
  end

  # Send a welcome email to the Manager of a new organization.
  #
  # @param [User] user
  # @param [Hash] opt
  #
  # @return [void]
  #
  # @see AccountMailer#new_org_email
  #
  def generate_new_org_email(user, **opt)
    prm = url_parameters.slice(*ApplicationMailer::MAIL_OPT).except!(:to)
    opt = prm.merge!(opt, item: user)
    AccountMailer.with(opt).new_org_email.deliver_later
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Send a welcome email to all new users of a new the organization.
  # In addition, manager users will receive #new_org_email.
  #
  # @param [Org, Array<User>] org
  # @param [Hash]             opt
  #
  # @return [void]
  #
  # @see MailConcern#generate_new_user_email
  # @see MailConcern#generate_new_org_email
  #
  def generate_new_org_emails(org, **opt)
    usr = org.is_a?(Org) ? org.contacts.to_a : org
    unless usr.is_a?(Array) && usr.first.is_a?(User)
      raise "invalid org (#{org.class}) #{org.inspect}"
    end
    prm = url_parameters.slice(*ApplicationMailer::MAIL_OPT).except!(:to)
    opt = prm.merge!(opt)
    man = usr.none?(&:manager?)
    usr.each do |user|
      generate_new_org_email(user, **opt) if man || user.manager?
      generate_new_user_email(user, **opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether JIRA help tickets should be created.
  #
  def send_help_ticket?
    mail_parameter?(:ticket)
  end

  # Send a request email in order to generate a JIRA help ticket for a new
  # enrollment request.
  #
  # @param [Enrollment] enrollment
  # @param [Hash]       opt           To ActionMailer::Parameterized#with
  #
  # @return [void]
  #
  # @see EnrollmentMailer#request_email
  #
  def generate_enrollment_ticket(enrollment, **opt)
    prm = url_parameters.slice(*ApplicationMailer::MAIL_OPT)
    opt = prm.merge!(opt, item: enrollment)
    EnrollmentMailer.with(opt).request_email.deliver_later
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether the given URL parameter indicates that a category of mail
  # should be generated.
  #
  # In production, mail generation is assumed unless explicitly turned off;
  # anywhere else, mail generation happens only if explicitly turned on.
  #
  # @param [Symbol] name              Name of the URL parameter to check.
  #
  def mail_parameter?(name)
    generate = params[name]
    production_deployment? ? !false?(generate) : true?(generate)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
