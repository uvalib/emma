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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for all external lookup services.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  CONFIGURATION =
    I18n.t('emma.service.lookup').transform_values { |service_config|
      service_config.dup.tap do |cfg|
        api_key        = cfg[:api_key].to_s
        cfg[:api_key]  = ENV[api_key] if api_key.match?(/^[A-Z][A-Z0-9_]+$/)
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
    # noinspection RubyMismatchedReturnType
    id_split(item).map! { |v| id_obj(v, **opt) }.compact
  end

  # Analyze a string into individual items.
  #
  # @param [Array, String, PublicationIdentifier, *] item
  #
  # @return [Array<String,PublicationIdentifier>]
  #
  def id_split(item)
    case item
      when Array                 then array = item.flat_map { |v| id_split(v) }
      when String                then array = item.split(/[ \t]*[,;\n]+[ \t]*/)
      when PublicationIdentifier then array = Array.wrap(item)
      else                            array = Array.wrap(item).map(&:to_s)
    end
    array.compact_blank!
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
    # noinspection RubyNilAnalysis, RubyMismatchedReturnType
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

  protected

  def __debug_job(*args, **opt)
    opt[:separator] ||= "\n\t"
    tid   = Thread.current.name
    name  = self.is_a?(Class) ? self.name : self.class.name
    args  = args.join(Emma::Debug::DEBUG_SEPARATOR)
    added = block_given? && yield || {}
    __debug_items("#{name} #{args}", **opt) do
      added.is_a?(Hash) ? added.merge(thread: tid) : [*added, "thread #{tid}"]
    end
  end
    .tap { |meth| neutralize(meth) unless DEBUG_JOB }

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)