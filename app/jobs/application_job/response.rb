# app/jobs/application_job/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for message objects that include job information.
#
# == Implementation Notes
# This class can't be implemented as a subclass of Hash because the ActiveJob
# serializer will fail to distinguish it from a simple Hash (and thereby fail
# to engage its custom serializer/deserializer).
#
# @see ApplicationCable::Response
#
class ApplicationJob::Response

  include ApplicationCable::Payload
  include Serializable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  DEFAULT_STATUS = 'INITIALIZING'

  TEMPLATE = ApplicationCable::Response::TEMPLATE

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Response data values.
  #
  # At a minimum, this includes the entries defined by #template.
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
  # @param [ApplicationJob::Response, Hash, *] values
  # @param [Hash, nil]                         error
  # @param [Hash, nil]                         diagnostic
  # @param [Hash]                              opt
  #
  def initialize(values = nil, error: nil, diagnostic: nil, **opt)
    if values.is_a?(self.class)
      error      ||= values.error
      diagnostic ||= values.diagnostic
      values       = values.table
    end
    # noinspection RubyMismatchedArgumentType
    @table      = set_payload(values, **opt)
    @error      = error
    @diagnostic = diagnostic
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
      when :diagnostic then diagnostic
      when :error      then error
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
      when :diagnostic then self.diagnostic = value
      when :error      then self.error      = value
      else                  table[key]      = value
    end
  end

  delegate_missing_to :table

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Create a new instance from *item* if it is not already an instance.
  #
  # @param [ApplicationJob::Response, *] item
  #
  # @return [ApplicationJob::Response]
  #
  def self.wrap(item)
    item.is_a?(self) ? item : new(item)
  end

  def self.template = TEMPLATE

  def self.default_status = DEFAULT_STATUS

  delegate :template, :default_status, to: :class

  # ===========================================================================
  # :section: ApplicationJob::Response::Serializer
  # ===========================================================================

  protected

  # Create a serializer for this class and any subclasses derived from it.
  #
  # @param [Class] this_class
  #
  # @see Serializer::Base#serialize?
  #
  def self.make_serializers(this_class, keys: %i[table error diagnostic])
    this_class.class_exec do

      serializer :serialize do |instance|
        keys.map { |k| [k, instance.send(k)] }.to_h.compact
      end

      serializer :deserialize do |hash|
        new(re_symbolize_keys(hash))
      end

      def self.inherited(subclass)
        make_serializers(subclass)
      end

    end
  end

  make_serializers(self)

end

__loading_end(__FILE__)
