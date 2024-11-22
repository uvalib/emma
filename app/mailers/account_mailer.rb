# app/mailers/account_mailer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class AccountMailer < ApplicationMailer

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

  # Generate a welcome email for a new EMMA user.
  #
  # @param [Hash] opt
  #
  # @return [Mail::Message]
  #
  def new_user_email(**opt)
    new_welcome_email(key: :new_user, **opt)
  end

  # Generate a welcome email for a new manager.
  #
  # @param [Hash] opt
  #
  # @return [Mail::Message]
  #
  def new_man_email(**opt)
    new_welcome_email(key: :new_man, **opt)
  end

  # Generate a welcome email for the manager of a new organization.
  #
  # @param [Hash] opt
  #
  # @return [Mail::Message]
  #
  def new_org_email(**opt)
    new_welcome_email(key: :new_org, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate a welcome email based on configuration from "en.emma.mail".
  #
  # If this is not the production deployment, the email subject will be
  # annotated to indicate that this is not a real message.
  #
  # @param [Symbol] key               Entry under "en.emma.mail".
  # @param [Hash]   opt               Passed to ActionMailer::Base#mail.
  #
  # @return [Mail::Message]
  #
  def new_welcome_email(key:, **opt)
    test  = opt.key?(:test) ? opt.delete(:test) : !production_deployment?
    @item = params[:item]
    @elem = email_elements(key, **opt, test: test)
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
  # :section: ApplicationMailer overrides
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
    opt[:format] ||= :html
    html = (opt[:format] == :html)
    cont = html ? contact_email : CONTACT_EMAIL
    help = html ? help_email    : HELP_EMAIL
    super.merge!(contact_email: cont, help_email: help)
  end

end

__loading_end(__FILE__)
