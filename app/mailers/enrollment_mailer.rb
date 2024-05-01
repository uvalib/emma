# app/mailers/enrollment_mailer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class EnrollmentMailer < ApplicationMailer

  include Emma::Config
  include Emma::Project

  include ActionView::Helpers::UrlHelper

  # ===========================================================================
  # :section: Mailer settings
  # ===========================================================================

  self.delivery_job = MailerJob

  default to: ENROLL_EMAIL, from: ENROLL_EMAIL

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL/form parameters associated with enrollment request emails.
  #
  # @type [Array<Symbol>]
  #
  URL_PARAMETERS = [:ticket, *MAIL_OPT].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Send to produce a JIRA help ticket for a new enrollment request.
  #
  # If this is not the production deployment, the email subject will be
  # annotated to indicate that this is not a real enrollment request.
  #
  # @param [Hash] opt
  #
  def request_email(**opt)
    test  = opt.key?(:test) ? opt.delete(:test) : !production_deployment?
    @item = params[:item]
    @elem = email_elements(:enroll_request, **opt, test: test)
    test  = test && @elem[:testing] || {}

    # Setup mail options.
    opt             = params.slice(*MAIL_OPT).merge!(opt)
    opt[:from]    ||= @item.requesting_user[:email] || ENROLL_EMAIL
    opt[:subject] ||= [@elem[:subject], @item.long_name].compact.join(' - ')
    opt[:subject] &&= test[:subject] % opt[:subject] if test[:subject].present?

    # Send the email to generate a help ticket.
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
    item = opt[:item]
    id   = item&.id || 1 # Might be nil only from EnrollmentMailerPreview.

    vals = super
    show = show_enrollment_url(id: id)
    list = enrollment_index_url
    org  = org_from(item)&.inspect || '[ORG]'
    name = name_from(item)         || '[NAME]'
    com  = comments_from(item)     || '[NONE]'

    if html
      l_opt = { target: '_top' } # Needed for EnrollmentMailerPreview.
      vals[:show] = link_to(show, show, l_opt)
      vals[:list] = link_to(list, list, l_opt)
      vals[:org]  = ERB::Util.h(org)
      vals[:name] = ERB::Util.h(name)
      vals[:comments] =
        com.split(PARAGRAPH).map { |v| html_paragraph(v) }.join("\n").html_safe
      # noinspection RubyMismatchedReturnType
      vals
    else
      vals.merge!(show: show, list: list, org: org, name: name, comments: com)
    end
  end

  # Extract organization name.
  #
  # @param [Enrollment, nil] item
  #
  # @return [String, nil]
  #
  def org_from(item)
    item&.long_name&.presence
  end

  # Extract name/email.
  #
  # @param [Enrollment, nil] item
  #
  # @return [String, nil]
  #
  def name_from(item)
    user = item&.requesting_user&.presence or return
    addr = user[:email].presence
    name = [user[:first_name], user[:last_name]].compact_blank.presence
    name = name&.join(' ')
    (name && addr) && "#{addr} (#{name})" || addr || name
  end

  # Extract request comments.
  #
  # @param [Enrollment, nil] item
  #
  # @return [String, nil]
  #
  def comments_from(item)
    lines = item&.request_notes&.presence or return
    lines = lines.to_s.split(/;?\n/) unless lines.is_a?(Array)
    lines.join(PARAGRAPH)
  end

end

__loading_end(__FILE__)
