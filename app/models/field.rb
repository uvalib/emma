# app/models/field.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for classes for representation of data fields.
#
module Field

  # A field based on a range of values defined by an EnumType.
  #
  class Range

    # The class which determines the range of possible values.
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

    # The value(s) associated with the instance.
    #
    # @return [Array]
    #
    attr_reader :values

    # The data field associated with the instance.
    #
    # @return [Symbol]
    #
    attr_reader :field

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize a new instance.
    #
    # @param [Symbol, Object]        src
    # @param [Symbol, String, Array] values
    #
    def initialize(src, values = nil)
      if values.is_a?(Symbol)
        @field = values
        @base  = Upload.get_field_configuration(@field)[:type]
        values = (src.emma_metadata[@field] if src.is_a?(Upload))
        values ||=
          begin
            src = src.emma_record if src.is_a?(Upload)
            src.send(@field) if src.respond_to?(@field)
          end
      else
        @field = nil
        @base  = src
      end
      case @base
        when Symbol    then @base = @base.to_s.constantize
        when 'boolean' then @base = TrueFalse
        else                @base = String
      end
      @values = Array.wrap(values).map { |v| v.to_s.strip.presence }.compact
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether this instance is unassociated with any field values.
    #
    def empty?
      values.blank?
    end

    # Either :single or :multiple, depending on the subclass.
    #
    # @return [Symbol]
    #
    def mode
      self.class.mode
    end

    # The resolved value for this field instance.
    #
    # @return [Array<String>, String, nil]
    #
    def content
      value = values
      value = value.map { |v| base.pairs[v] || v } if base.respond_to?(:pairs)
      (mode == :single) ? value.first : value
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Either :single or :multiple, depending on the subclass.
    #
    # @return [Symbol]
    #
    def self.mode
      safe_const_get(:MODE, true) || :multiple
    end

  end

  # A field which may have multiple values from a range.
  #
  class Multi < Range
    MODE = :multiple
  end

  # A field which may have a single value from a range.
  #
  class Select < Range
    MODE = :single
  end

  # A field which may have multiple values.
  #
  class Collection < Range
    MODE = :multiple
  end

  # A field which may have a single value.
  #
  class Single < Range
    MODE = :single
  end

  # Special-case for a binary (true/false/unset) field.
  #
  class Binary < Select
  end

end

__loading_end(__FILE__)
