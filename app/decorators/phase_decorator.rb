# app/decorators/phase_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/phase" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Phase]
#
class PhaseDecorator < BaseDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for Phase

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Paths
    include BaseDecorator::Paths
  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module Methods
    include BaseDecorator::Methods
  end

  # Definitions available to instances of either this decorator or its related
  # collection decorator.
  #
  # (Definitions that are only applicable to instances of this decorator but
  # *not* to collection decorator instances are not included here.)
  #
  module InstanceMethods
    include BaseDecorator::InstanceMethods, Paths, Methods
  end

  # Definitions available to both this decorator class and the related
  # collector decorator class.
  #
  # (Definitions that are only applicable to this class but *not* to the
  # collection class are not included here.)
  #
  module ClassMethods
    include BaseDecorator::ClassMethods, Paths, Methods
  end

  # Cause definitions to be included here and in the associated collection
  # decorator via BaseCollectionDecorator#collection_of.
  #
  module Common
    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end
  end

  include Common

end

__loading_end(__FILE__)
