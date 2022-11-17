# app/helpers/emma_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods for describing the EMMA grant and project.
#
module EmmaHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # EMMA grant partners
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
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

  # Generate a textual list of EMMA partners.
  #
  # @param [Symbol, nil] type         One of :academic, :commercial, :all (def)
  # @param [Symbol]      mode         One of :brief or :long (default).
  # @param [String]      separator    Separator between items.
  # @param [String]      final        Connector for final :long format item.
  #
  # @return [String]
  #
  def emma_partner_list(type = nil, mode: :long, separator: ',', final: 'and')
    list =
      emma_partners(type).map { |key, partner|
        name = partner&.dig(:name) || partner&.dig(:tag) || key.to_s.upcase
        name.try(:dig, mode) || name
      }.compact
    separator += ' ' if %w( , ; ).include?(separator)
    separator ||= ' '
    if mode == :brief
      list.join(separator)
    elsif list.size < 3
      # noinspection RubyMismatchedArgumentType
      final = ' ' + final if final && !final.start_with?(/\s/)
      final = final + ' ' if final && !final.match?(/\s$/)
      list.join(final || separator)
    else
      final += ' ' if final && !final.end_with?(' ')
      # noinspection RubyNilAnalysis
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
    # noinspection RubyMismatchedArgumentType
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

  private

  def self.included(base)
    __included(base, self)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
