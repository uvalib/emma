# app/services/lookup_service/_response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A collection of identifiers transformed into PublicationIdentifier and
# grouped by type.
#
# == Implementation Notes
# This class can't be implemented as a subclass of Hash because the ActiveJob
# serializer will fail to distinguish it from a simple Hash (and thereby fail
# to engage its custom serializer/deserializer).
#
class LookupService::Response

  include LookupService::Common

  include Serializable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  DEF_STATUS  = 'INITIALIZING'
  DEF_SERVICE = 'unknown'

  # Response data value entries.
  #
  # @type [Hash]
  #
  TEMPLATE = {
    status:   DEF_STATUS,   # Request status.
    service:  DEF_SERVICE,  # Originating external lookup service.
    duration: 0.0,          # Time in seconds to receive the requested results.
    late:     nil,          # Overdue by this many seconds.
    user:     nil,          # Requesting user.
    time:     nil,          # When the response was received.
    data:     {},           # Response result data.
  }.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Response data values.
  #
  # At a minimum, this includes the entries defined by #TEMPLATE.
  #
  # @return [Hash]
  #
  attr_reader :table

  # Out-of-band error information.
  #
  # @return [Hash,nil]
  #
  attr_reader :error

  # Out-of-band diagnostic information.
  #
  # @return [Hash,nil]
  #
  attr_reader :diagnostic

  # Create a new instance.
  #
  # @param [LookupService::Response, Hash, *] items
  # @param [Hash, nil]                        opt
  #
  def initialize(items = nil, opt = nil)
    src = nil
    case items
      when LookupService::Response then @table = items.table.deep_dup
      when Hash                    then src    = items
      else Log.warn("#{self.class}: #{items.class} unexpected")
    end
    @table ||= TEMPLATE.transform_values { |v| v.dup if v.is_a?(Hash) }
    # noinspection RubyMismatchedArgumentType
    @table.merge!(src) if src.present?
    @table.merge!(opt) if opt.present?
    @error      = @table.delete(:error)
    @diagnostic = @table.delete(:diagnostic)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return all except out-of-band information.
  #
  # @return [Hash]
  #
  def to_h
    table.compact
  end

  # Fetch a stored value, allowing access to #error and #diagnostic as
  # :error and :diagnostic, respectively.
  #
  # @param [Symbol] key
  #
  # @return [*]
  #
  def [](key)
    case key
      when :error      then error
      when :diagnostic then diagnostic
      else                  table[key]
    end
  end

  # Update a stored value, allowing access to #error and #diagnostic as
  # :error and :diagnostic, respectively.
  #
  # @param [Symbol] key
  # @param [*]      value
  #
  # @return [*]
  #
  def []=(key, value)
    case key
      when :error      then @error      = value
      when :diagnostic then @diagnostic = value
      else                  table[key]  = value
    end
  end

  delegate_missing_to :@table

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Create a new instance from *item* if it is not already an instance.
  #
  # @param [LookupService::Response, *] item
  #
  # @return [LookupService::Response]
  #
  def self.wrap(item)
    item.is_a?(self) ? item : new(item)
  end

  # ===========================================================================
  # :section: LookupService::Request::Serializer
  # ===========================================================================

  public

  serializer :serialize do |item|
    item.to_h
  end

  serializer :deserialize do |value|
    re_symbolize_keys(value)
  end

end

__loading_end(__FILE__)
