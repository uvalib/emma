# app/types/emma_repository.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - EmmaRepository
#
# "Identifier for a repository"
#
# @see "en.emma.repository.*"
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.6#/components/schemas/EmmaRepository  JSON schema specification
#
class EmmaRepository < EnumType

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Partner repository configurations.
  #
  # @type [Hash{Symbol=>any}]
  #
  CONFIGURATION = config_section(:repository).deep_freeze

  # The default repository for uploads.
  #
  # @type [String]
  #
  # @see "en.emma.repository._default"
  #
  DEFAULT = CONFIGURATION[:_default]

  # Values associated with each past or present source repository.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see "en.emma.repository"
  # @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.6#/components/schemas/EmmaRepository  JSON schema specification
  #
  ENTRY =
    CONFIGURATION.map { |repo, config|
      next if repo.start_with?('_')
      [repo, config.merge(default: (repo.to_s == DEFAULT))]
    }.compact.to_h.deep_freeze

  # Values associated with each currently-active source repository.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see "en.emma.repository"
  # @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.6#/components/schemas/EmmaRepository  JSON schema specification
  #
  ACTIVE =
    ENTRY.select { |_, config|
      active = config[:active]
      if active.is_a?(String)
        case
          when !(env = ENV_VAR[active]).nil?        then active = env
          when !(con = safe_const_get(active)).nil? then active = con
        end
      end
      true?(active)
    }.deep_freeze

  # The repositories that require the "partner repository workflow".
  #
  # @type [Array<Symbol>]
  #
  PARTNER = ACTIVE.select { |_, config| config[:partner] }.keys.freeze

  # The repositories that can handle "partner repository workflow" requests.
  #
  # If the repository is not also in #PARTNER then related
  # submissions are handled as EMMA-native, but with the additional step of
  # reflecting the submission in the S3 bucket.
  #
  # @type [Array<Symbol>]
  #
  S3_QUEUE = ACTIVE.select { |_, c| c[:s3] unless c[:default] }.keys.freeze

  # The repositories that represent EMMA publisher collections.
  #
  # @type [Array<Symbol>]
  #
  COLLECTION = ACTIVE.select { |_, config| config[:collection] }.keys.freeze

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # The repositories that require the "partner repository workflow".
  #
  # @type [Array<Symbol>]
  #
  def self.partner
    PARTNER
  end

  # The repositories that can handle "partner repository workflow" requests.
  #
  # If the repository is not also in #PARTNER then related
  # submissions are handled as EMMA-native, but with the additional step of
  # reflecting the submission in the S3 bucket.
  #
  # @type [Array<Symbol>]
  #
  def self.s3_queue
    S3_QUEUE
  end

  # The repositories that represent EMMA publisher collections.
  #
  # @type [Array<Symbol>]
  #
  def self.collection
    COLLECTION
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  define_enumeration do
    ACTIVE.transform_values { _1[:name] }.merge!(_default: DEFAULT)
  end

end

__loading_end(__FILE__)
