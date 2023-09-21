# app/models/ability/role.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Ability::Role

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Role prototypes.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RubyMismatchedConstantType
  #++
  ROLE_CONFIG = I18n.t('emma.role.type.RolePrototype')

  # Role capabilities.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RubyMismatchedConstantType
  #++
  CAPABILITY_CONFIG = I18n.t('emma.role.type.RoleCapability')

  # Role capabilities for each role prototype.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  CAPABILITIES =
    ROLE_CONFIG.transform_values do |entry|
      Array.wrap(entry[:capability]).compact_blank.map!(&:to_sym)
    end

  # A mapping of role capability to the lowest role prototype supporting it.
  #
  # @type [Hash{Symbol,Symbol}]
  #
  CAPABILITY_ROLE = {
    developing:     :developer,
    administering:  :administrator,
    managing:       :manager,
    downloading:    :member,
    submitting:     :staff,
    searching:      :guest,
  }.freeze

  if sanity_check?
    CAPABILITIES.map { |role, capabilities|
      invalid = capabilities - CAPABILITY_CONFIG.keys
      "#{role}: %s" % invalid.join(', ') if invalid.present?
    }.compact.tap { |invalid|
      if invalid.present?
        raise ['CAPABILITIES invalid:', *invalid].join("\n\t")
      end
    }
    (CAPABILITY_ROLE.keys - CAPABILITY_CONFIG.keys).tap do |invalid|
      if invalid.present?
        raise 'CAPABILITY_ROLE invalid keys: %s' % invalid.join(', ')
      end
    end
    (CAPABILITY_ROLE.values - ROLE_CONFIG.keys).tap do |invalid|
      if invalid.present?
        raise 'CAPABILITY_ROLE invalid values: %s' % invalid.join(', ')
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  EnumType.add_enumerations(
    RolePrototype:  ROLE_CONFIG.transform_values { |v| v[:label] },
    RoleCapability: CAPABILITY_CONFIG.transform_values { |v| v[:label] },
  )

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

# =============================================================================
# Generate top-level classes associated with each enumeration entry so that
# they can be referenced without prepending a namespace.
# =============================================================================

public

# @see Ability#ROLE_CONFIG
class RolePrototype < EnumType; end

# @see Ability#CAPABILITY_CONFIG
class RoleCapability < EnumType; end

__loading_end(__FILE__)
