# app/types/_scalar_type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

Boolean = Axiom::Types::Boolean

# Base class for custom scalar types.
#
class ScalarType

  include Comparable
  include Emma::Common
  include Emma::Constants
  include Emma::TypeMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    include Emma::Common
    include Emma::Constants

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Default value for items of this type.
    #
    # @return [String]
    #
    def default
      ''
    end

    # Indicate whether *v* matches the default value.
    #
    # @param [any, nil] v
    #
    def default?(v)
      false
    end

    # Indicate whether `*v*` would be a valid value for an item of this type.
    #
    # @param [any, nil] v
    #
    def valid?(v)
      !v.nil?
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def normalize(v)
      v = clean(v)
      v.is_a?(String) ? v.strip : v.to_s
    end

    # Resolve an item into its value.
    #
    # @param [any, nil] v
    #
    # @return [any, nil]
    #
    def clean(v)
      v = v.value if v.is_a?(Field::Type)
      v = v.value if v.is_a?(ScalarType) && !v.is_a?(self_class)
      v = nil     if v == EMPTY_VALUE
      v.is_a?(Array) ? v.excluding(nil, EMPTY_VALUE) : v
    end

    # Type-cast an object to an instance of this type.
    #
    # @param [any, nil] v             Value to use or transform.
    # @param [Hash]     opt           Options passed to #create.
    #
    # @return [superclass, nil]
    #
    def cast(v, **opt)
      c = self_class
      v.is_a?(c) ? v : create(v, **opt)
    end

    # Create a new instance of this type.
    #
    # @param [any, nil] v             Value to use or transform.
    # @param [Hash]     opt           Options passed to #initialize.
    #
    # @return [superclass, nil]
    #
    def create(v, **opt)
      c = self_class
      if v.is_a?(c)
        v.dup
      elsif (v = normalize(v)).present?
        c.new(v, **opt)
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include Methods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The value wrapped by this instance.
  #
  # @return [String, nil]
  #
  attr_reader :value

  delegate_missing_to :value

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [any, nil] v               Optional initial value.
  # @param [Hash]     opt             Options passed to #set.
  #
  def initialize(v = nil, **opt)
    set(v, **opt)
  end

  # Assign a new value to the instance.
  #
  # @param [any, nil] v
  #
  # @return [String, nil]
  #
  # @note Currently unused.
  # :nocov:
  def value=(v)
    set(v)
  end
  # :nocov:

  # Assign a new value to the instance.
  #
  # @param [any, nil] v
  # @param [Boolean]  invalid         If *true*, allow invalid value.
  # @param [Boolean]  allow_nil       If *false*, use #default if necessary.
  # @param [Boolean]  warn            If *true*, log invalid.
  #
  # @return [String, nil]
  #
  def set(v, invalid: false, allow_nil: true, warn: false, **)
    v = nil if v == EMPTY_VALUE
    unless v.nil?
      @value = normalize(v)
      @value = nil unless valid?(@value)
      Log.warn { "#{type}: #{v.inspect}: not in #{values}" } if warn && !@value
    end
    @value ||= (v if invalid) || (default unless allow_nil)
  end

  # ===========================================================================
  # :section: ScalarType::Methods overrides
  # ===========================================================================

  public

  # Indicate whether the instance is valid, or indicate whether `*v*` would be
  # a valid value.
  #
  # @param [any, nil] v
  #
  def valid?(v = nil)
    v ||= value
    super
  end

  # Transform value into a valid form.
  #
  # @param [any, nil] v
  #
  # @return [String]
  #
  def normalize(v = nil)
    v ||= value
    super
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Return the string representation of the instance value.
  #
  # @return [String]
  #
  def to_s
    value.to_s
  end

  # Return the inspection of the instance value.
  #
  # @return [String]
  #
  def inspect
    "#{self.class}(#{to_s.inspect})"
  end

  # Indicate whether the instance has a blank value.
  #
  def blank?
    value.blank?
  end

  # Value needed to make instances comparable.
  #
  # @return [Integer]
  #
  def hash
    to_s.hash
  end

  # Value needed to make instances comparable.
  #
  # @param [any, nil] other
  #
  def eql?(other)
    to_s == other.to_s
  end

  # Return the value as represented within JSON.
  #
  # @return [String]
  #
  def to_json
    to_s.to_json
  end

  # Return the value as represented within JSON.
  #
  # @return [String]
  #
  def as_json
    to_s.as_json
  end

  # ===========================================================================
  # :section: Comparable
  # ===========================================================================

  public

  # Comparison operator required by the Comparable mixin.
  #
  # @param [any, nil] other
  #
  # @return [Integer]   -1 if self is later, 1 if self is earlier
  #
  def <=>(other)
    to_s <=> other.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The natural language presentation for the current enumeration value.
  #
  # @return [String]
  #
  def label
    to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a serializer class associated with the given *base*.
  #
  # @param [Class] base
  #
  # @return [void]
  #
  def self.define_serializer(base = self)
    base.class_exec do

      include Serializable

      serializer :serialize do |item|
        item.value
      end

    end
  end

  # Create a serializer class associated with the given *base* and arrange for
  # any subclasses to have their own serializers.
  #
  # @param [Class] base
  #
  # @return [void]
  #
  def self.generate_serializer(base = self)
    define_serializer(base)
    base.class_exec do
      # noinspection RbsMissingTypeSignature
      def self.inherited(subclass)
        generate_serializer(subclass)
      end
    end
  end

  generate_serializer

end

__loading_end(__FILE__)
