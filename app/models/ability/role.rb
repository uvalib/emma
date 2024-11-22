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
  PROTOTYPE_CONFIG = EnumType::CONFIGURATION.dig(:ability, :RolePrototype)

  # Role capabilities.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  CAPABILITY_CONFIG = EnumType::CONFIGURATION.dig(:ability, :RoleCapability)

  # Role capabilities for each role prototype.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  CAPABILITIES =
    PROTOTYPE_CONFIG.transform_values { |entry|
      Array.wrap(entry[:capability]).compact_blank.map!(&:to_sym)
    }.deep_freeze

  # A mapping of role capability to the lowest role prototype supporting it.
  #
  # @type [Hash{Symbol,Symbol}]
  #
  CAPABILITY_ROLE =
    CAPABILITY_CONFIG.transform_values { |entry|
      entry[:prototype]&.to_sym || :observer
    }.deep_freeze

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
    (CAPABILITY_ROLE.values - PROTOTYPE_CONFIG.keys).tap do |invalid|
      if invalid.present?
        raise 'CAPABILITY_ROLE invalid values: %s' % invalid.join(', ')
      end
    end
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
