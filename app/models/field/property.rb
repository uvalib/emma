# app/models/field/property.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Field::Property

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Record field configuration property keys found under "emma.*.record.*".
  #
  # @type [Array<Symbol>]
  #
  CONFIGURATION_KEYS = [
    :cond,        # Conditional display criteria. (not in "emma.*.record.*")
    :help,        # Help topic locator. (not in "emma.*.record.*")
    :label,       # Field label.
    :max,         # Maximum allowed;  0 or nil implies no limit.
    :min,         # Minimum required; 0 or nil implies optional field.
    :notes,       # Detailed notes that can be displayed near the field.
    :notes_html,
    :origin,      # If present the field is not user-modifiable.
    :placeholder, # Text to display in <textarea> or <input type="text">.
    :role,        # Field visible only to a user with this role.
    :tooltip,     # Tooltip when hovering over field label.
    :type,        # A symbol or 'text', 'textarea', 'number', 'datetime', etc.
    :category,    # Logical field grouping value.
  ].freeze

  # Record field configuration property keys created dynamically.
  #
  # @type [Array<Symbol>]
  #
  SYNTHETIC_KEYS = [
    :array,
    :field,
    :ignored,
    :readonly,
    :required,
  ].freeze

  # Record field configuration property keys within a Field::Type instance.
  #
  # @type [Array<Symbol>]
  #
  PROPERTY_KEYS = (CONFIGURATION_KEYS + SYNTHETIC_KEYS).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Normalize entry values.
  #
  # @param [Hash]        prop         Passed to #normalize
  # @param [Symbol, nil] field        Passed to #normalize
  #
  def normalize!(prop, field = nil)
    field ||= prop&.dig(:field)
    prop.replace(normalize(prop, field))
  end

  # Ensure that field entry values are cleaned up and have the expected type.
  #
  # @param [Hash, String, Symbol] prop
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
  # @option entry [Symbol]         :role
  #
  # @return [Hash]
  #
  # === Usage Notes
  # The :type indicates the type of HTML input element, either directly or
  # indirectly.  If the value is a Symbol it is interpreted as a derivative of
  # Model or EnumType which gives the range of values for a '<select>' element
  # or the set of checkboxes to create within a 'role="listbox"' element.  Any
  # other value indicates '<textarea>' or the '<input>' type attribute to use.
  #
  def normalize(prop, field = nil)
    prop = prop.to_s.titleize            if prop.is_a?(Symbol)
    prop = { label: prop }               if prop.is_a?(String)
    prop = {}                            unless prop.is_a?(Hash)
    prop = { field: field }.merge!(prop) if field && !prop.key?(:field)
    prop = prop.merge(field: field)      if field && (prop[:field] != field)
    prop.map { |item, value|
      case item
        when :min, :max then value = value&.to_i
        when :help      then value = Array.wrap(value).map(&:to_sym)
        when :type      then value = value_class(value) || value.to_s
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
  # @param [Hash{Symbol=>*}] prop
  # @param [Symbol, nil]     field
  #
  # @return [Hash{Symbol=>*}]         The modified *prop* entry.
  #
  def finalize!(prop, field = nil)
    sub = prop.except(:cond).select { |_, v| v.is_a?(Hash) }
    set = (sub.present? ? %i[field] : [*SYNTHETIC_KEYS, :type]) - prop.keys
    set = set.excluding(:field) if field.blank?
    set = set.map { |k| [k, true] }.to_h
    org = prop[:origin].to_s
    min = prop[:min].to_i
    max = prop[:max].to_i
    ary = prop.key?(:max) && prop[:max].nil?

    prop[:ignored]  = prop[:max].present? && !max.positive? if set[:ignored]
    prop[:required] = prop[:min].present? &&  min.positive? if set[:required]
    prop[:readonly] = org.remove('user').present?           if set[:readonly]
    prop[:array]    = ary || (min > 1) || (max > 1)         if set[:array]
    prop[:type]   ||= prop[:array] ? 'textarea' : 'text'    if set[:type]
    prop[:field]  ||= field                                 if set[:field]

    # Sub-fields under :file_data or :emma_data.
    sub.each_pair { |k, v| prop[k] = finalize!(v, k) }

    reorder!(prop)
  end

  # Indicate whether the field configuration should be unused.
  #
  # @param [Hash]                prop
  # @param [Symbol, String, nil] action
  #
  def unused?(prop, action = nil)
    action   = action&.to_sym
    cond     = prop&.dig(:cond) || prop || {}
    o, e     = cond.values_at(:only, :except).map { |v| Array.wrap(v) if v }
    unused   = (o == [])
    unused ||= o && (o.include?(:none) || (action && !o.include?(action)))
    unused ||= e && (e.include?(:all)  || (action &&  e.include?(action)))
    unused || false
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Regenerate an entry with the fields in an order more helpful for logging.
  #
  # @param [Hash] prop                Passed to #reorder.
  #
  # @return [Hash]                    The modified *prop* entry.
  #
  def reorder!(prop)
    prop.replace(reorder(prop))
  end

  # Generate a copy of an entry with the fields in an order more helpful for
  # logging.
  #
  # @param [Hash] prop
  #
  # @return [Hash]                    A modified copy of *prop*.
  #
  def reorder(prop)
    src = prop.dup
    dst = {}
    %i[field label type].each { |k| dst[k] = src.delete(k) if src.key?(k) }
    src.keys.each    { |k| dst[k] = src.delete(k) unless src[k].is_a?(Hash) }
    %i[actions].each { |k| dst[k] = src.delete(k) if src.key?(k) }
    src.keys.each    { |k| dst[k] = reorder(src[k]) }
    dst
  end

  # Normalize :except and :only values.
  #
  # @param [Hash] prop
  #
  # @return [Hash]
  #
  def normalize_conditions(prop)
    result       = { except: nil, only: nil }
    conditions   = prop&.dig(:cond) || prop&.slice(*result.keys) || {}
    except, only = conditions.values_at(*result.keys)
    result[:only] ||=
      if (only &&= symbol_array(only))
        disable = only.empty? || only.include?(:none)
        result[:except] = %i[all] if disable
        disable ? %i[none] : only.excluding(:all).presence
      end
    result[:except] ||=
      if (except &&= symbol_array(except))
        disable = except.include?(:all)
        disable ? %i[all] : except.excluding(:none).presence
      end
    result
  end

  # Return an enumeration or model class expressed or implied by *value*.
  #
  # @param [String, Symbol, Class, *] value
  #
  # @return [Class, nil]
  #
  def value_class(value)
    return TrueFalse if value.to_s.strip.casecmp?('boolean')
    value = value.to_s.safe_constantize if value.is_a?(Symbol)
    # noinspection RubyMismatchedReturnType
    value if value.is_a?(Class) && [EnumType, Model].any? { |t| value < t }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Cast *item* as an array of Symbols.
  #
  # @param [String, Symbol, Array] item
  #
  # @return [Array<Symbol>]
  #
  def symbol_array(item)
    Array.wrap(item).compact.map!(&:to_sym)
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
