# app/models/field.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for classes for representation of data fields.
#
module Field

  # ===========================================================================
  # :section: Modules
  # ===========================================================================

  public

  # Methods for fields which should have only a single value.
  #
  module SingleValued

    # Initialize a new instance.
    #
    # @param [Symbol, Object]        src
    # @param [Symbol, String, Array] value
    #
    def initialize(src, value = nil)
      super(src, :single, value)
    end

    # The single value for this field instance.
    #
    # @return [String, nil]
    #
    def value
      values.first
    end

  end

  # Methods for fields which may have multiple values.
  #
  module MultiValued

    # Initialize a new instance.
    #
    # @param [Symbol, Object]        src
    # @param [Symbol, String, Array] values
    #
    def initialize(src, values = nil)
      super(src, :multiple, values)
    end

  end

  # ===========================================================================
  # :section: Classes
  # ===========================================================================

  public

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

    # Either :single or :multiple.
    #
    # @return [Symbol]
    #
    attr_reader :mode

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
    # @param [Symbol]                mode
    # @param [Symbol, String, Array] values
    #
    def initialize(src, mode = nil, values = nil)
      # noinspection RubyCaseWithoutElseBlockInspection
      case src
        when Upload
          @field = values&.to_sym
          values = src.emma_record&.send(@field)
        when Search::Api::Record
          @field = values&.to_sym
          values = src.send(@field)
      end
      @base = @field && Upload.get_field_configuration(@field)[:type] || String
      @base = @base.to_s.constantize if @base.is_a?(Symbol)
      @mode = mode&.to_sym || self.mode || :multiple
      @values = Array.wrap(values).reject(&:blank?)
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

  end

  # A field which may have multiple values from a range.
  #
  class Multi < Range
    include MultiValued
  end

  # A field which may have a single value from a range.
  #
  class Select < Range
    include SingleValued
  end

  # A field which may have multiple values.
  #
  class Collection < Range
    include MultiValued
  end

  # A field which may have a single value.
  #
  class Single < Range
    include SingleValued
  end

end

__loading_end(__FILE__)
