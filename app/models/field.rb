# app/models/field.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'search'

# Namespace for classes that manage the representation of data fields involved
# in search, ingest or upload.
#
module Field

  SYNTHETIC_KEYS       = %i[field ignored required readonly array type].freeze
  SYNTHETIC_PROPERTIES = SYNTHETIC_KEYS.map { |k| [k, true] }.to_h.freeze

  # ===========================================================================
  # :section: Configuration
  # ===========================================================================

  public

  # Return an enumeration type expressed or implied by *value*.
  #
  # @param [String, Symbol, Class, *] value
  #
  # @return [Class] The class indicated by *value*.
  # @return [nil]   If *value* could not be cast a subclass of EnumType.
  #
  def self.enum_type(value)
    if value.is_a?(Class)
      value if value < EnumType
    elsif value.to_s.strip.casecmp?('boolean')
      TrueFalse
    elsif value.is_a?(Symbol)
      value.to_s.safe_constantize
    end
  end

  # field_configuration
  #
  # @param [Symbol]       field
  # @param [Hash, String] entry
  #
  # @option entry [Integer, nil]   :min
  # @option entry [Integer, nil]   :max
  # @option entry [String]         :label
  # @option entry [String]         :tooltip
  # @option entry [String, Array]  :help          Help popup topic/subtopic.
  # @option entry [String]         :notes         Inline notes.
  # @option entry [String]         :notes_html    Inline HTML notes.
  # @option entry [String]         :placeholder   Input area placeholder text.
  # @option entry [Symbol, String] :type          See Usage Notes [1]
  # @option entry [String]         :origin
  #
  # @return [Hash]
  #
  # == Usage Notes
  # The :type indicates the type of HTML input element, either directly or
  # indirectly.  If the value is a Symbol it is interpreted as an EnumType
  # subclass which gives the range of values for a <select> element or the set
  # of checkboxes to create within a <fieldset> element.  Any other value
  # indicates <textarea> or the <input> type attribute to use.
  #
  #--
  # noinspection RubyNilAnalysis, RubyCaseWithoutElseBlockInspection
  #++
  def self.field_configuration(field, entry)
    return unless entry.is_a?(Hash)
    entry.map { |item, value|
      case item
        when :min, :max then value = value&.to_i
        when :help      then value = Array.wrap(value).map(&:to_sym)
        when :type      then value = enum_type(value) || value.to_s
        when /_html$/   then value = value.to_s.strip.html_safe
        else
          # Sub-field under :file_data or :emma_data.
          value = send(__method__, item, value) if value.is_a?(Hash)
      end
      value = value.reject(&:blank?) if value.is_a?(Array)
      value = value.strip if value.is_a?(String) && !value.html_safe?
      [item, value]
    }.to_h.tap { |h|
      set = SYNTHETIC_PROPERTIES
      set = set.slice(:field) if h[:type] == 'json'
      if set[:array]
        h[:array]   = (h.key?(:max) && h[:max].nil?)
        h[:array] ||= (h[:max].present? && h[:max] > 1)
        h[:array] ||= (h[:min].present? && h[:min] > 1)
      end
      h[:ignored]  = h[:max].present? && !h[:max].positive?   if set[:ignored]
      h[:required] = h[:min].to_i.positive?                   if set[:required]
      h[:readonly] = h[:origin].to_s.remove('user').present?  if set[:readonly]
      h[:type]   ||= h[:array] ? 'textarea' : 'text'          if set[:type]
      h[:field]  ||= field                                    if set[:field]
    }
  end

  # ===========================================================================
  # :section: Configuration
  # ===========================================================================

  public

  # Field property configuration values.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  CONFIG =
    I18n.t('emma.upload.record').transform_values { |field|
      field_configuration(field)
    }.deep_freeze

  # Configuration properties for the given field.
  #
  # @param [Symbol, String, nil] field
  #
  # @return [Hash]
  #
  def self.configuration(field)
    f = field&.to_sym
    CONFIG[f] || CONFIG.dig(:emma_data, f) || CONFIG.dig(:file_data, f) || {}
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # Generate an appropriate field subclass instance if possible.
  #
  # @param [Upload] item
  # @param [Symbol] field
  #
  # @return [Field::Type]             Instance based on *item* and *field*.
  # @return [nil]                     If *field* is not valid.
  #
  def self.for(item, field)
    return if (cfg = configuration(field)).blank?
    array = cfg[:array]
    range = cfg[:type]
    range = nil unless range.is_a?(Class) && (range < EnumType)
    if range && array
      Field::MultiSelect.new(item, field)
    elsif range == TrueFalse
      Field::Binary.new(item, field)
    elsif range
      Field::Select.new(item, field)
    elsif array
      Field::Collection.new(item, field)
    else
      Field::Single.new(item, field)
    end
  end

  # ===========================================================================
  # :section: Subclasses
  # ===========================================================================

  public

  # Base class for field type descriptions.
  #
  class Type

    # The class for the value of the Type instance.
    #
    # If this a derivative of EnumType then `base.values` defines the set of
    # possible values.
    #
    # If it's something else (String by default) then it defines the type of
    # value that may be associated with the instance.
    #
    # @return [Class]
    #
    attr_reader :base

    # The data field associated with the instance.
    #
    # @return [Symbol]
    #
    attr_reader :field

    # The value(s) associated with the instance (empty if :base is not an
    # EnumType).
    #
    # @return [Array]
    #
    attr_reader :range

    # The value associated with the instance.
    #
    # @return [*]
    #
    attr_reader :value

    # A positive indicator of whether the instance has been given a value.
    #
    # @return [FalseClass, TrueClass]
    #
    attr_reader :valid

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize a new instance.
    #
    # @param [Symbol, Object] src
    # @param [Symbol]         field
    # @param [*]              value
    #
    def initialize(src, field = nil, value = nil)
      @base  = src
      @field = @range = nil
      if field.is_a?(Symbol)
        @field = field
        @base  = Field.configuration(@field)[:type]
        @range ||=
          if src.respond_to?(:active_emma_metadata)
            src.active_emma_metadata[@field]
          elsif src.respond_to?(:emma_metadata)
            src.emma_metadata[@field]
          end
        @range ||=
          begin
            if src.respond_to?(:active_emma_record)
              src = src.active_emma_record
            elsif src.respond_to?(:emma_record)
              src = src.emma_record
            end
            src.send(@field) if src.respond_to?(@field)
          end
      end
      @range = Array.wrap(@range).map { |v| v.to_s.strip.presence }.compact
      @base  = @base.to_s.safe_constantize if @base.is_a?(Symbol)
      @base  = self.class.base unless @base.is_a?(Class)
      @value = value || @range.presence
      @valid = !@value.nil?
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The resolved value for this field instance.
    #
    # @return [Array<String>, String, nil]
    #
    def content
      res = value.presence || range
      res = Array.wrap(res)
      res = res.map { |v| base.pairs[v] || v } if base.respond_to?(:pairs)
      (mode == :single) ? res.first : res
    end

    # The raw value for this field instance.
    #
    # @return [*, nil]
    #
    def value
      @value
    end

    # Give the instance a value.
    #
    # @param [*] new_value
    #
    # @return [*]
    #
    def set(new_value)
      @valid = !new_value.nil?
      @value = new_value
    end

    # Remove any value from the instance.
    #
    # @return [nil]
    #
    def clear
      set(nil)
    end

    # Indicate whether this instance is associated with a value.
    #
    def set?
      valid
    end

    # Indicate whether this instance is not associated with a value.
    #
    def unset?
      !valid
    end

    # Either :single or :multiple, depending on the subclass.
    #
    # @return [Symbol]
    #
    def mode
      self.class.mode
    end

    alias_method :empty?, :unset?
    alias_method :blank?, :unset?

    # =========================================================================
    # :section: Class methods
    # =========================================================================

    public

    # Either :single or :multiple, depending on the subclass.
    #
    # @return [Symbol]
    #
    def self.mode
      safe_const_get(:MODE, true) || :single
    end

    # The enumeration type on which the subclass is based.
    #
    # @return [Class, nil]
    #
    def self.base
      safe_const_get(:BASE, true) || String
    end

  end

  # ===========================================================================
  # :section: Subclasses for fields based on scalar values
  # ===========================================================================

  public

  # A field which may have a single value.
  #
  class Single < Type
    MODE = :single
  end

  # A field which may have multiple values.
  #
  class Collection < Type
    MODE = :multiple
  end

  # ===========================================================================
  # :section: Subclasses for fields based on enumerations
  # ===========================================================================

  public

  # A field based on a range of values defined by an EnumType.
  #
  class Range < Type

    # =========================================================================
    # :section: Field::Type overrides
    # =========================================================================

    public

    # Indicate whether this instance is unassociated with any field values.
    #
    def empty?
      super && range.blank?
    end

    # Give the instance a value.
    #
    # @param [*] new_value
    #
    # @return [Array]   If mode == :multiple
    # @return [*]       If mode == :single
    #
    def set(new_value)
      @valid = true
      if mode == :single
        @value = Array.wrap(new_value).first
      else
        @value ||= []
        @value += Array.wrap(new_value)
        @value.uniq! || @value
      end
    end

  end

  # ===========================================================================
  # :section: Subclasses for fields with controlled value(s)
  # ===========================================================================

  public

  # A field which may have multiple values from a range.
  #
  class MultiSelect < Range
    MODE = :multiple
  end

  # A field which may have a single value from a range.
  #
  class Select < Range
    MODE = :single
  end

  # Special-case for a binary (true/false/unset) field.
  #
  class Binary < Select
    BASE = TrueFalse
  end

end

__loading_end(__FILE__)
