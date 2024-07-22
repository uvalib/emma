# app/helpers/emma_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods for describing the EMMA grant and project.
#
module EmmaHelper

  include Emma::Project

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # EMMA grant partner configurations.
  #
  # @type [Hash{Symbol=>any}]
  #
  EMMA_PARTNER_CONFIG = config_section(:grant, :partner).deep_freeze

  # Past or present EMMA grant partners.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  EMMA_PARTNER_ENTRY =
    EMMA_PARTNER_CONFIG.reject { |k, _| k.start_with?('_') }.deep_freeze

  # Active EMMA grant partners.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  EMMA_PARTNER =
    EMMA_PARTNER_ENTRY.transform_values { |section|
      section.select { |_, entry| entry[:active] }
    }.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # List EMMA academic partners.
  #
  # @param [Hash] opt                 To #emma_partner_list.
  #
  # @return [String]
  #
  def academic_partners(**opt)
    emma_partner_list(**opt, type: :academic)
  end

  # List EMMA commercial partners.
  #
  # @param [Hash] opt                 To #emma_partner_list.
  #
  # @return [String]
  #
  def commercial_partners(**opt)
    emma_partner_list(**opt, type: :commercial)
  end

  # Generate a textual list of EMMA partners.
  #
  # @param [Symbol] mode              One of :brief or :long (default).
  # @param [String] separator         Separator between items.
  # @param [String] final             Connector for final :long format item.
  # @param [Hash]   opt               Passed to #emma_partners.
  #
  # @return [String]
  #
  def emma_partner_list(mode: :long, separator: ',', final: 'and', **opt)
    separator   = "#{separator} " if %w[ , ; ].include?(separator)
    separator ||= ' '
    list =
      emma_partners(**opt).map { |key, partner|
        name = partner&.dig(:name) || partner&.dig(:tag) || key.to_s.upcase
        name.try(:dig, mode) || name
      }.compact
    if (mode == :brief) || !final || !list.many?
      list.join(separator)
    elsif list.size == 2
      list.join(" #{final.strip} ")
    else
      list[...-1].join(separator) << "#{separator}#{final.strip} " << list[-1]
    end
  end

  # Get a selection of EMMA partners.
  #
  # @param [Symbol]       type        One of :academic, :commercial, or :all.
  # @param [Boolean, nil] active      If *nil*, all partners past and present.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def emma_partners(type: :all, active: true, **)
    cfg = active ? EMMA_PARTNER : EMMA_PARTNER_ENTRY
    if cfg.is_a?(FalseClass)
      cfg = cfg.transform_values { |s| s.reject { |_, e| e[:active] } }
    end
    case type
      when :all      then {}.merge!(*cfg.values)
      when *cfg.keys then cfg[type]
      else Log.warn { "#{__method__}: #{type.inspect} not in #{cfg.keys}" }; {}
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A simple "mailto:" link for project email contact.
  #
  # @param [String, nil] label        Link text instead of the email address.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def project_email(label = nil)
    mail_to(PROJECT_EMAIL, label)
  end

  # A simple "mailto:" link for the general email contact.
  #
  # @param [String, nil] label        Link text instead of the email address.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def contact_email(label = nil)
    mail_to(CONTACT_EMAIL, label)
  end

  # A simple "mailto:" link for the support email.
  #
  # @param [String, nil] label        Link text instead of the email address.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def help_email(label = nil)
    mail_to(HELP_EMAIL, label)
  end

  # The "mailto:" link for the general email contact.
  #
  # @param [String, nil] label        Link text instead of the email address.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emma_administrator(label = nil)
    label ||= config_text(:administrator)
    contact_email(label)
  end

  # A simple "mailto:" link for the "emma-users" mailing list.
  #
  # @param [String, nil] label        Link text instead of the email address.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def mailing_list_email(label = nil)
    mail_to(MAILING_LIST_EMAIL, label)
  end

  # A link to the "emma-users" mailing list site.
  #
  # @param [String, nil] label        Link text instead of the URL.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def mailing_list_site(label = nil)
    url     = MAILING_LIST_SITE
    label ||= url
    link_to(label, url)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
