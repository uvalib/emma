# app/models/field.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for classes that manage the representation of data fields involved
# in search, ingest or upload.
#
module Field

  # ===========================================================================
  # :section: Configuration
  # ===========================================================================

  public

  DEFAULT_MODEL        = :upload

  SYNTHETIC_KEYS       = %i[field ignored required readonly array type].freeze
  SYNTHETIC_PROPERTIES = SYNTHETIC_KEYS.map { |k| [k, true] }.to_h.freeze

  # Record field configuration property fields.
  #
  # @type [Array<Symbol>]
  #
  PROPERTY_KEYS = [
    :cond,        # Conditional display criteria.
    :help,        # Help topic locator.
    :label,       # Field label.
    :max,         # Maximum allowed;  0 or nil implies no limit.
    :min,         # Minimum required; 0 or nil implies optional field.
    :notes,       # Detailed notes that can be displayed near the field.
    :origin,      # If present the field is not user-modifiable.
    :placeholder, # Text to display in <textarea> or <input type="text">.
    :role,        # Field visible only to a user with this role.
    :tooltip,     # Tooltip when hovering over field label.
    :type,        # A symbol or 'text', 'textarea', 'number', 'datetime', etc.
    :category,    # Logical field grouping value.
  ].freeze

  # ===========================================================================
  # :section: Configuration
  # ===========================================================================

  public

  # Return an enumeration type expressed or implied by *value*.
  #
  # @param [String, Symbol, Class, Any] value
  #
  # @return [Class] The class indicated by *value*.
  # @return [nil]   If *value* could not be cast a subclass of EnumType.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def self.enum_type(value)
    if value.is_a?(Class)
      value if value < EnumType
    elsif value.to_s.strip.casecmp?('boolean')
      TrueFalse
    elsif value.is_a?(Symbol)
      value.to_s.safe_constantize
    end
  end

  # Configuration properties for a field within a given model/controller.
  #
  # @param [Symbol, String, Array, nil] field
  # @param [Symbol, String, nil]        model
  # @param [Symbol, String, nil]        action
  #
  # @return [Hash]                    Frozen result.
  #
  #--
  # == Variations
  #++
  #
  # @overload configuration_for(field, model = nil, action = nil)
  #   Look the named field in the configuration subtree for *action* if given
  #   and then in the :all subtree.  For hierarchical configurations (currently
  #   only for submissions), the top-level is checked for *field* and then
  #   the sub-sections within :emma_data, :file_data, and :file_data :metadata.
  #   @param [Symbol, String, nil]        field
  #   @param [Symbol, String, Hash, nil]  model
  #   @param [Symbol, String, nil]        action
  #
  # @overload configuration_for(field_path, model = nil, action = nil)
  #   The field name to check is taken from the end of the array; the remainder
  #   is used to limit the sub-section to check.
  #   @param [Array<Symbol,String,Array>] field_path
  #   @param [Symbol, String, Hash, nil]  model
  #   @param [Symbol, String, nil]        action
  #
  def self.configuration_for(field, model = nil, action = nil)
    if field.is_a?(Array)
      sub_sections = field[...-1] || []
      field        = field.last
    else
      sub_sections = [nil, :emma_data, :file_data, [:file_data, :metadata]]
    end
    return {} if (field = field&.to_sym).blank?
    config = Model.config_for(model || DEFAULT_MODEL)
    [action, :all].find do |section|
      next unless (section = section&.to_sym)
      next unless (section_cfg = config[section]).is_a?(Hash)
      sub_sections.find do |sub_sec|
        sub_section_cfg = sub_sec ? section_cfg.dig(*sub_sec) : section_cfg
        next unless sub_section_cfg.is_a?(Hash)
        field_cfg = sub_section_cfg[field]
        return field_cfg if field_cfg.is_a?(Hash)
      end
    end
    {}
  end

  # Find the field whose configuration entry has a matching label.
  #
  # @param [String, Symbol, nil] label
  # @param [Symbol, String, nil] model
  # @param [Symbol, String, nil] action
  #
  # @return [Hash]                    Frozen result.
  #
  def self.configuration_for_label(label, model = nil, action = nil)
    return {} if (label = label.to_s).blank?
    config       = Model.config_for(model || DEFAULT_MODEL)
    sub_sections = [nil, :emma_data, :file_data, [:file_data, :metadata]]
    [action, :all].find do |section|
      next unless (section = section&.to_sym)
      next unless (section_cfg = config[section]).is_a?(Hash)
      sub_sections.find do |sub_sec|
        sub_section_cfg = sub_sec ? section_cfg.dig(*sub_sec) : section_cfg
        next unless sub_section_cfg.is_a?(Hash)
        sub_section_cfg.find do |_, fld_cfg|
          return fld_cfg if fld_cfg.is_a?(Hash) && (fld_cfg[:label] == label)
        end
      end
    end
    {}
  end

  # ===========================================================================
  # :section: Configuration
  # ===========================================================================

  public

  # Normalize entry values.
  #
  # @param [Hash]        entry        Passed to #normalize
  # @param [Symbol, nil] field        Passed to #normalize
  #
  def self.normalize!(entry, field = nil)
    field ||= entry&.dig(:field)
    entry.replace(normalize(entry, field))
  end

  # Ensure that field entry values are cleaned up and have the expected type.
  #
  # @param [Hash, String, Symbol] entry
  # @param [Symbol, nil]          field
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
  # @option entry [String]         :role
  #
  # @return [Hash]
  #
  # == Usage Notes
  # The :type indicates the type of HTML input element, either directly or
  # indirectly.  If the value is a Symbol it is interpreted as an EnumType
  # subclass which gives the range of values for a '<select>' element or the
  # set of checkboxes to create within a '<fieldset>' element.  Any other value
  # indicates '<textarea>' or the '<input>' type attribute to use.
  #
  def self.normalize(entry, field = nil)
    entry = entry.to_s.titleize            if entry.is_a?(Symbol)
    entry = { label: entry }               if entry.is_a?(String)
    entry = {}                             unless entry.is_a?(Hash)
    entry = { field: field }.merge!(entry) if field && !entry.key?(:field)
    entry = entry.merge(field: field)      if field && (entry[:field] != field)
    entry.map { |item, value|
      case item
        when :min, :max then value = value&.to_i
        when :help      then value = Array.wrap(value).map(&:to_sym)
        when :type      then value = enum_type(value) || value.to_s
        when :role      then value = value&.to_sym
        when /_html$/   then value = value.to_s.strip.html_safe
        when :cond      then value = normalize_conditions(value)
      end
      case value
        when Hash   then value = normalize(value, item) unless item == :cond
        when Array  then value = value.compact_blank
        when String then value = value.strip unless value.html_safe?
      end
      [item, value]
    }.to_h
  end

  # Generate derived fields for an entry.
  #
  # @param [Hash{Symbol=>Any}] entry
  # @param [Symbol, nil]       field
  #
  # @return [Hash{Symbol=>Any}]       The modified *entry*.
  #
  def self.finalize!(entry, field = nil)
    e   = entry
    set = SYNTHETIC_PROPERTIES
    set = set.slice(:field)  if e[:type] == 'json'
    set = set.except(:field) if field.blank?
    min = e[:min].to_i
    max = e[:max].to_i
    ary = e.key?(:max) && e[:max].nil?

    e[:ignored]  = e[:max].present? && !max.positive?       if set[:ignored]
    e[:required] = e[:min].present? && min.positive?        if set[:required]
    e[:readonly] = e[:origin].to_s.remove('user').present?  if set[:readonly]
    e[:array]    = ary || (min > 1) || (max > 1)            if set[:array]
    e[:type]   ||= e[:array] ? 'textarea' : 'text'          if set[:type]
    e[:field]  ||= field                                    if set[:field]

    # Sub-fields under :file_data or :emma_data.
    e.each_pair do |k, v|
      e[k] = finalize!(v, k) if v.is_a?(Hash) && (k != :cond)
    end

    reorder!(e)
  end

  # Indicate whether the field configuration should be unused.
  #
  # @param [Hash]                entry
  # @param [Symbol, String, nil] action
  #
  def self.unused?(entry, action = nil)
    action = action&.to_sym
    e, o   = (entry&.dig(:cond) || entry || {}).values_at(:except, :only)
    unused   = (o == [])
    unused ||= (o && (action && !o.include?(action) || o.include?(:none)))
    unused ||= (e && (action && e.include?(action)  || e.include?(:all)))
    unused || false
  end

  # ===========================================================================
  # :section: Configuration
  # ===========================================================================

  protected

  # Regenerate an entry with the fields in an order more helpful for logging.
  #
  # @param [Hash] entry               Passed to #reorder.
  #
  # @return [Hash]                    The modified *entry*.
  #
  def self.reorder!(entry)
    entry.replace(reorder(entry))
  end

  # Generate a copy of an entry with the fields in an order more helpful for
  # logging.
  #
  # @param [Hash] entry
  #
  # @return [Hash]                    A modified copy of *entry*.
  #
  def self.reorder(entry)
    src = entry.dup
    dst = {}
    %i[field label type].each { |k| dst[k] = src.delete(k) if src.key?(k) }
    src.keys.each    { |k| dst[k] = src.delete(k) unless src[k].is_a?(Hash) }
    %i[actions].each { |k| dst[k] = src.delete(k) if src.key?(k) }
    src.keys.each    { |k| dst[k] = reorder(src[k]) }
    dst
  end

  # Normalize :except and :only values.
  #
  # @param [Hash] entry
  #
  # @return [Hash]
  #
  def self.normalize_conditions(entry)
    result       = { except: nil, only: nil }
    conditions   = entry&.dig(:cond) || entry&.slice(*result.keys) || {}
    except, only = conditions.values_at(*result.keys)
    result[:only] ||=
      unless only.nil?
        disable = (only == []) || (only = symbol_array(only)).include?(:none)
        result[:except] = %i[all] if disable
        disable ? %i[none] : (only - %i[all]).presence
      end
    result[:except] ||=
      unless except.nil?
        disable = (except = symbol_array(except)).include?(:all)
        disable ? %i[all] : (except - %i[none]).presence
      end
    result
  end

  # ===========================================================================
  # :section: Configuration
  # ===========================================================================

  private

  # Cast *item* as an array of Symbols.
  #
  # @param [String, Symbol, Array] item
  #
  # @return [Array<Symbol>]
  #
  def self.symbol_array(item)
    Array.wrap(item).compact.map(&:to_sym)
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # Generate an appropriate field subclass instance if possible.
  #
  # @param [Model, Any]          item
  # @param [Symbol]              field
  # @param [Symbol, String, nil] model
  # @param [*]                   value
  # @param [Hash, nil]           config
  #
  # @return [Field::Type]             Instance based on *item* and *field*.
  # @return [nil]                     If *field* is not valid.
  #
  def self.for(item, field, model = nil, value: nil, config: nil)
    model  ||= Model.for(item)
    config ||= configuration_for(field, model)
    return if config.blank?

    array = true?(config[:array])
    range = config[:type].then { |v| v if v.is_a?(Class) && (v < EnumType) }

    if    range && array     then type = Field::MultiSelect
    elsif range == TrueFalse then type = Field::Binary
    elsif range              then type = Field::Select
    elsif array              then type = Field::Collection
    else                          type = Field::Single
    end
    type.new(item, field, model, value)
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
    # @return [Any]
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
    # @param [Symbol, Model, Any]  src
    # @param [Symbol, nil]         field
    # @param [Symbol, String, nil] model
    # @param [*]                   value
    #
    #--
    # noinspection RubyMismatchedVariableType
    #++
    def initialize(src, field = nil, model = nil, value = nil)
      @base  = src
      @field = @range = nil
      if field.is_a?(Symbol)
        @field = field
        @base  = Field.configuration_for(@field, model)[:type]
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
            # noinspection RubyMismatchedArgumentType
            src.try(@field)
          end
      end
      @range = Array.wrap(@range).map { |v| v.to_s.strip.presence }.compact
      @base  = @base.to_s.safe_constantize if @base.is_a?(Symbol)
      @base  = self.class.base unless @base.is_a?(Class)
      @value = value.presence || @range.presence
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
    # @return [Any]
    #
    def value
      @value
    end

    # Give the instance a value.
    #
    # @param [Any, nil] new_value
    #
    # @return [Any]
    #
    def set(new_value)
      val    = new_value.presence
      @valid = !val.nil?
      @value = val
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
    # @return [Array]                 If mode == :multiple
    # @return [*]                     If mode == :single
    #
    def set(new_value)
      @valid = true
      if mode == :single
        # noinspection RubyMismatchedReturnType
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
