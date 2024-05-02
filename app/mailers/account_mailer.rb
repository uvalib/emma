# app/mailers/account_mailer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class AccountMailer < ApplicationMailer

  include Emma::Config
  include Emma::Project

  include EmmaHelper

  include ActionView::Helpers::UrlHelper

  # ===========================================================================
  # :section: Mailer settings
  # ===========================================================================

  self.delivery_job = MailerJob

  default from: CONTACT_EMAIL

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL/form parameters associated with account emails.
  #
  # @type [Array<Symbol>]
  #
  URL_PARAMETERS = [:welcome, *MAIL_OPT].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Send a welcome email to a new EMMA user.
  #
  # If this is not the production deployment, the email subject will be
  # annotated to indicate that this is not a real enrollment request.
  #
  # @param [Hash] opt
  #
  def new_user_email(**opt)
    test  = opt.key?(:test) ? opt.delete(:test) : !production_deployment?
    @item = params[:item]
    @elem = email_elements(:new_user, **opt, test: test)
    test  = test && @elem[:testing] || {}

    # Setup mail options.
    opt             = params.merge(opt).slice(*MAIL_OPT)
    opt[:to]        = join_addresses(@item.email_address, opt[:to], @elem[:to])
    opt[:cc]        = join_addresses(opt[:cc],  @elem[:cc]).presence
    opt[:bcc]       = join_addresses(opt[:bcc], @elem[:bcc]).presence
    opt[:from]    ||= @elem[:from] || CONTACT_EMAIL
    opt[:subject] ||= @elem[:subject]
    opt[:subject] &&= test[:subject] % opt[:subject] if test[:subject].present?

    # Send the email to the user.
    mail(opt) do |format|
      format.text
      format.html
    end
  end

  # Send a welcome email to the manager of a new organization.
  #
  # If this is not the production deployment, the email subject will be
  # annotated to indicate that this is not a real enrollment request.
  #
  # @param [Hash] opt
  #
  def new_org_email(**opt)
    test  = opt.key?(:test) ? opt.delete(:test) : !production_deployment?
    @item = params[:item]
    @elem = email_elements(:new_org, **opt, test: test)
    test  = test && @elem[:testing] || {}

    # Setup mail options.
    opt             = params.merge(opt).slice(*MAIL_OPT)
    opt[:to]        = join_addresses(@item.email_address, opt[:to], @elem[:to])
    opt[:cc]        = join_addresses(opt[:cc],  @elem[:cc]).presence
    opt[:bcc]       = join_addresses(opt[:bcc], @elem[:bcc]).presence
    opt[:from]    ||= @elem[:from] || CONTACT_EMAIL
    opt[:subject] ||= @elem[:subject]
    opt[:subject] &&= test[:subject] % opt[:subject] if test[:subject].present?

    # Send the email to the user.
    mail(opt) do |format|
      format.text
      format.html
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Supply interpolation values for the current email.
  #
  # @param [Hash, nil] vals
  # @param [Hash]      opt
  #
  # @return [Hash]
  #
  def interpolation_values(vals = nil, **opt)
    html = (opt[:format] == :html)
    vals = super
    vals[:contact_email] = html ? contact_email : CONTACT_EMAIL
    vals[:help_email]    = html ? help_email    : HELP_EMAIL
    # noinspection RubyMismatchedReturnType
    vals
  end

end

__loading_end(__FILE__)
