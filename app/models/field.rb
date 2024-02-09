# app/models/field.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for classes that manage the representation of data fields involved
# in search, ingest or upload.
#
module Field

  include Field::Property
  include Field::Configuration

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  DEFAULT_MODEL = :upload

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # Generate an appropriate field subclass instance if possible.
  #
  # @param [any, nil]         item    Symbol, String, Class, Model
  # @param [Symbol, nil]      field
  # @param [any, nil]         value
  # @param [FieldConfig, nil] prop
  #
  # @return [Field::Type]             Instance based on *item* and *field*.
  # @return [nil]                     If *field* is not valid.
  #
  def self.for(item, field, value: nil, prop: nil)
    prop ||= configuration_for(field, Model.for(item)).presence or return
    range  = value_class(prop[:type])
    array  = true?(prop[:array])
    case
      when range && array     then type = Field::MultiSelect
      when range == TrueFalse then type = Field::Binary
      when range              then type = Field::Select
      when array              then type = Field::Collection
      else                         type = Field::Single
    end
    type.new(item, field, prop: prop, value: value)
  end

end

__loading_end(__FILE__)
