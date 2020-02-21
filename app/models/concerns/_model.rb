# app/models/concerns/_model.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common model methods.
#
module Model

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The fields defined by this model.
  #
  # @return [Array<Symbol>]
  #
  def field_names
    instance_variables.map { |v| v.to_s.delete_prefix('@').to_sym }.sort
  end

  # The fields and values for this model instance.
  #
  # @return [Hash{Symbol=>*}]
  #
  def fields
    field_names.map { |field|
      [field, send(field)] rescue nil
    }.compact.to_h
  end

end

__loading_end(__FILE__)
