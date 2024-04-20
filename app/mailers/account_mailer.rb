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
  def welcome_email(**opt)
    test  = opt.key?(:test) ? opt.delete(:test) : !production_deployment?
    @item = params[:item]
    @elem = welcome_email_elements(**params, **opt, test: test)
    test  = test && @elem[:testing] || {}

    # Setup mail options.
    opt             = params.slice(*MAIL_OPT).merge!(opt)
    opt[:to]      ||= @item.email_address
    opt[:from]    ||= CONTACT_EMAIL
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

  # Generate mailer message content for #welcome_email.
  #
  # If this is not the production deployment, the heading and body will be
  # annotated to indicate that this is not a real enrollment request.
  #
  # @param [User] item
  # @param [Hash] opt
  #
  # @option opt [Symbol]  :format
  # @option opt [Boolean] :test
  #
  # @return [Hash]
  #
  def welcome_email_elements(item: @item, **opt)
    test = opt.key?(:test) ? opt.delete(:test) : !production_deployment?
    html = (opt[:format] == :html)

    # Get configured welcome email elements.
    config_section('emma.project.welcome', **opt).tap do |cfg|

      cfg[:body] = format_paragraphs(cfg[:body], **opt)

      # Interpolation happens afterwards to preserve HTML safety.
      vals = {
        contact_email: html ? contact_email : CONTACT_EMAIL,
        help_email:    html ? help_email    : HELP_EMAIL,
      }
      cfg[:body].map! { |paragraph| interpolate(paragraph, **vals) }

      if test && (test = cfg[:testing]).present?
        if (h = test[:heading]).present?
          cfg[:heading] = h % cfg[:heading]
        end
        if (b = test[:body]).present?
          b = format_paragraphs(b, **opt)
          b.map! { |v| content_tag(:strong, v) } if html
          cfg[:body] += b
        end
      end

    end
  end

end

__loading_end(__FILE__)
