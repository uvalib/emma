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
    @elem = request_email_elements(**params, **opt, test: test)
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

  # Generate mailer message content for #request_email.
  #
  # If this is not the production deployment, the heading and body will be
  # annotated to indicate that this is not a real enrollment request.
  #
  # @param [Hash] opt
  #
  # @option opt [Enrollment] :item    Default: @item.
  # @option opt [Symbol]     :format
  # @option opt [Boolean]    :test
  #
  # @return [Hash]
  #
  def request_email_elements(**opt)
    test = opt.key?(:test) ? opt.delete(:test) : !production_deployment?
    html = (opt[:format] == :html)
    item = opt.delete(:item) || @item
    id   = item.id || 1 # Might be nil only from EnrollmentMailerPreview.

    # Get configured enrollment request email elements.
    config_section('emma.enroll.request', **opt).deep_dup.tap do |cfg|

      cfg[:body] = format_paragraphs(cfg[:body], **opt)

      # Interpolation happens afterwards to preserve HTML safety.
      vals = {
        show: show_enrollment_url(id: id),
        list: enrollment_index_url,
        org:  org_from(item)&.inspect || '[ORG]',
        name: name_from(item)         || '[NAME]'
      }
      if html
        l_opt = { target: '_top' } # Needed for EnrollmentMailerPreview.
        vals[:show] = link_to(vals[:show], vals[:show], l_opt)
        vals[:list] = link_to(vals[:list], vals[:list], l_opt)
        vals[:org]  = ERB::Util.h(vals[:org])
        vals[:name] = ERB::Util.h(vals[:name])
      end
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

end

__loading_end(__FILE__)
