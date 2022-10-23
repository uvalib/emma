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
  # :section: Definitions shared with PhasesDecorator
  # ===========================================================================

  public

  module SharedPathMethods
    include BaseDecorator::SharedPathMethods
  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module SharedGenericMethods
    include BaseDecorator::SharedGenericMethods
  end

  # Definitions available to instances of either this decorator or its related
  # collection decorator.
  #
  # (Definitions that are only applicable to instances of this decorator but
  # *not* to collection decorator instances are not included here.)
  #
  module SharedInstanceMethods
    include BaseDecorator::SharedInstanceMethods
    include SharedPathMethods
    include SharedGenericMethods
  end

  # Definitions available to both this decorator class and the related
  # collector decorator class.
  #
  # (Definitions that are only applicable to this class but *not* to the
  # collection class are not included here.)
  #
  module SharedClassMethods
    include BaseDecorator::SharedClassMethods
    include SharedPathMethods
    include SharedGenericMethods
  end

  # Cause definitions to be included here and in the associated collection
  # decorator via BaseCollectionDecorator#collection_of.
  #
  module SharedDefinitions
    def self.included(base)
      base.include(SharedInstanceMethods)
      base.extend(SharedClassMethods)
    end
  end

end

class PhaseDecorator

  include SharedDefinitions

end

__loading_end(__FILE__)
