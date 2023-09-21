# lib/emma/type_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# For inclusion in classes whose types may be stored in data structures that
# are liable to be duplicated so that the reference to the class does not
# become a reference to a duplicate class.
#
# By default, #dup and #deep_dup will create a copy of an item, including
# values which are classes themselves (not instances of classes).
#
# For items which are classes, e.g.:
#
#   { item: ScalarType }
#
# this would mean that the duplicated result would be something like:
#
#   { item: #<Class:0x00005590b0d928a8> }
#
# Overriding both #dup and #duplicable? for the class itself (not instances)
# is required to avoid generating these duplicate classes and allow the
# class itself to be copied to the destination as would be expected.
#
module Emma::TypeMethods

  extend ActiveSupport::Concern

  class_methods do

    # By default, Object#deep_dup will create a copy of an item, including
    # values which are classes themselves (not instances of classes).
    #
    # Returning *false* here prevents Object#deep_dup from treating the class
    # type as a duplicable item.
    #
    # @see Emma::TypeMethods
    #
    def duplicable?
      false
    end

    # By default, Object#dup will create a copy of an item, including values
    # which are classes themselves (not instances of classes).
    #
    # Returning *self* here overrides the normal behavior of Class#dup so that
    # the class itself is returned rather than a duplicate of the class.
    #
    # @see Emma::TypeMethods
    #
    def dup
      self
    end

  end

end

__loading_end(__FILE__)
