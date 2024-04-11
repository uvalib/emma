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

  default to: ENROLL_EMAIL, from: ENROLL_EMAIL

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
    test  = opt.key?(:test) ? opt.delete(:test) : not_deployed?
    @item = params[:item]
    @elem = request_email_elements(**params, **opt, test: test)

    # Setup mail options.
    opt             = params.slice(:from, :subject).merge!(opt)
    opt[:from]    ||= @item.requesting_user[:email] || ENROLL_EMAIL
    opt[:subject] ||= [@elem[:subject], @item.long_name].compact.join(' - ')
    test_subject    = (@elem.dig(:testing, :subject) if test)
    opt[:subject] &&= test_subject % opt[:subject]   if test_subject.present?

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

  # Generate mailer message content for :request_email.
  #
  # If this is not the production deployment, the heading and body will be
  # annotated to indicate that this is not a real enrollment request.
  #
  # @param [Enrollment] item
  # @param [Hash]       opt
  #
  # @option opt [String] :show        URL to the enrollment item.
  # @option opt [String] :list        URL to all enrollment items.
  # @option opt [Symbol] :format
  #
  # @return [Hash]
  #
  def request_email_elements(item: @item, **opt)
    test = opt.key?(:test) ? opt.delete(:test) : not_deployed?
    html = (opt[:format] == :html)
    id   = item.id || 1 # Might be nil only from EnrollmentMailerPreview.

    # Setup interpolation values for #config_section.
    opt[:show] ||= show_enrollment_url(id: id)
    opt[:list] ||= enrollment_index_url
    opt[:org]  ||= org_from(item)&.inspect || '[ORG]'
    opt[:name] ||= name_from(item)         || '[NAME]'

    # Prepare interpolation values so that 'emma.enroll.body' is HTML-safe.
    if html
      l_opt = { target: '_top' } # Needed for EnrollmentMailerPreview.
      opt[:show] = link_to(opt[:show], opt[:show], l_opt)
      opt[:list] = link_to(opt[:list], opt[:list], l_opt)
      opt[:org]  = ERB::Util.h(opt[:org])
      opt[:name] = ERB::Util.h(opt[:name])
    end

    # Get configured enrollment request email elements.
    config_section('emma.enroll', **opt).tap do |cfg|

      test_heading  = (cfg.dig(:testing, :heading).presence          if test)
      test_body     = (Array.wrap(cfg.dig(:testing, :body)).presence if test)
      test_body     = test_body&.map { |v| content_tag(:strong, v) } if html

      cfg[:heading] = test_heading % cfg[:heading]  if test_heading
      cfg[:body]    = Array.wrap(cfg[:body])
      cfg[:body]    = cfg[:body].map(&:html_safe)   if html
      cfg[:body]   += test_body                     if test_body

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

  # Extract name/e-mail.
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
