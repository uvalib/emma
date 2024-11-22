# app/records/concerns/api/serializer/obj.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process data passed in as an
# Obj (a Ruby [hash] object representation).
#
# @see Representable::Obj
# @see Api::Record::Schema::ClassMethods#schema
#
class Api::Serializer::Obj < Api::Serializer

  include Representable::Obj
  include Representable::Coercion

  include Api::Serializer::Obj::Schema
  include Api::Serializer::Obj::Associations

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  SERIALIZER_TYPE = :obj

  # ===========================================================================
  # :section: Api::Serializer overrides
  # ===========================================================================

  public

  # Type of serializer.
  #
  # @return [Symbol]                  Always :obj.
  #
  def serializer_type
    SERIALIZER_TYPE
  end

  # Render data elements.
  #
  # @param [Symbol, Proc] method
  # @param [Hash]         opt             Options argument for *method*.
  #
  # @return [String]
  #
  # @see Representable::Obj#to_obj
  #
  def serialize(method: :to_obj, **opt)
    super
  end

  # Load data elements.
  #
  # @param [String, Hash] data
  # @param [Symbol, Proc] method
  #
  # @return [Api::Record]
  # @return [nil]
  #
  # @see Representable::Obj#from_obj
  #
  def deserialize(data, method: :from_obj)
    super
  end

end

__loading_end(__FILE__)
