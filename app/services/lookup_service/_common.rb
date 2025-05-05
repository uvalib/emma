# app/services/lookup_service/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common support methods.
#
module LookupService::Common

  include Emma::Common
  include Emma::Debug
  include Emma::TimeMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for all external lookup services.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  CONFIGURATION =
    config_section(:service, :lookup).transform_values { |service_config|
      service_config.dup.tap do |cfg|
        key            = cfg[:api_key].to_s
        cfg[:api_key]  = ENV_VAR[key] if key.match?(/^[A-Z][A-Z0-9_]+$/)
        cfg[:types]    = Array.wrap(cfg[:types]).map(&:to_sym)
        cfg[:timeout]  = positive_float(cfg[:timeout]).to_f * SECONDS
        cfg[:priority] = positive(cfg[:priority])
        cfg[:enabled]  = true?(cfg[:enabled])
      end
    }.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a list of PublicationIdentifiers.
  #
  # @param [Array, String, nil] item
  # @param [Hash]               opt   Passed to #id_obj.
  #
  # @return [Array<PublicationIdentifier>]
  #
  def id_list(item, **opt)
    id_split(item).map! { id_obj(_1, **opt) }.compact
  end

  # Analyze a string into individual items.
  #
  # @param [any, nil] item            Array, String, PublicationIdentifier
  #
  # @return [Array<String,PublicationIdentifier>]
  #
  def id_split(item)
    case item
      when Array                 then item = item.flat_map { id_split(_1) }
      when String                then item = item.split(/[ \t]*[,;\n]+[ \t]*/)
      when PublicationIdentifier then item = item.presence
      else                            item = item&.to_s
    end
    Array.wrap(item).compact_blank
  end

  # Transform a type/ID pair.
  #
  # @param [PublicationIdentifier, Symbol, String, nil] type
  # @param [PublicationIdentifier, String, nil]         id
  # @param [Boolean]                                    copy
  #
  # @return [PublicationIdentifier, nil]
  #
  def id_obj(type, id = nil, copy: false, **)
    if type.is_a?(PublicationIdentifier)
      Log.warn("#{__method__}: ignoring id #{id.inspect}") if id
      copy ? type.dup : type

    elsif id.is_a?(PublicationIdentifier)
      Log.warn("#{__method__}: ignoring type #{type.inspect}") if type
      copy ? id.dup   : id

    elsif type.is_a?(Array)
      Log.warn("#{__method__}: ignoring id #{id.inspect}") if id
      id = type.compact.join(':')
      PublicationIdentifier.cast(id, invalid: true)

    else
      id = [type, id].compact.join(':')
      PublicationIdentifier.cast(id, invalid: true)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
