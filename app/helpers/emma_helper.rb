# app/helpers/emma_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods for describing the EMMA grant and project.
#
module EmmaHelper

  include Emma::Constants

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # EMMA grant partners
  #
  # @type [Hash{Symbol=>Hash}]
  #
  EMMA_PARTNER = I18n.t('emma.grant.partner').deep_freeze

  # EMMA grant partner categories.
  #
  # @type [Array<Symbol>]
  #
  EMMA_PARTNER_TYPE = EMMA_PARTNER.keys.freeze

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
    emma_partner_list(:academic, **opt)
  end

  # List EMMA commercial partners.
  #
  # @param [Hash] opt                 To #emma_partner_list.
  #
  # @return [String]
  #
  def commercial_partners(**opt)
    emma_partner_list(:commercial, **opt)
  end

  # Generate a textual list of EMMA partners.
  #
  # @param [Symbol, nil] type         One of :academic, :commercial, :all (def)
  # @param [Symbol]      mode         One of :brief or :long (default).
  # @param [String]      separator    Separator between items.
  # @param [String]      final        Connector for final :long format item.
  #
  # @return [String]
  #
  def emma_partner_list(
    type =      nil,
    mode:       :long,
    separator:  ',',
    final:      'and',
    **
  )
    list =
      emma_partners(type).map { |key, partner|
        name = partner&.dig(:name) || partner&.dig(:tag) || key.to_s.upcase
        name.try(:dig, mode) || name
      }.compact
    separator += ' ' if %w[ , ; ].include?(separator)
    separator ||= ' '
    if mode == :brief
      list.join(separator)
    elsif list.size < 3
      final = ' ' + final if final && !final.start_with?(/\s/)
      final = final + ' ' if final && !final.match?(/\s$/)
      list.join(final || separator)
    else
      final += ' ' if final && !final.end_with?(' ')
      list[0...-1].join(separator) << separator << final << list[-1]
    end
  end

  # Get a selection of EMMA partners.
  #
  # @param [Symbol, nil] type         One of :academic, :commercial, :all (def)
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def emma_partners(type = :all)
    if type.nil? || (type == :all)
      {}.merge!(*EMMA_PARTNER.values)
    elsif EMMA_PARTNER.key?(type)
      EMMA_PARTNER[type]
    else
      Log.warn { "#{__method__}: #{type.inspect} not in #{EMMA_PARTNER_TYPE}" }
      {}
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A simple "mailto:" link for project e-mail contact.
  #
  # @param [String, nil] label        Link text instead of the email address.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def project_email(label = nil)
    mail_to(PROJECT_EMAIL, label)
  end

  # A simple "mailto:" link for the general e-mail contact.
  #
  # @param [String, nil] label        Link text instead of the email address.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def contact_email(label = nil)
    mail_to(CONTACT_EMAIL, label)
  end

  # The "mailto:" link for the general e-mail contact.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emma_administrator(label = 'EMMA administrator') # TODO: I18n
    contact_email(label)
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
