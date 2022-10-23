# app/decorators/action_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/action" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Action]
#
class ActionDecorator < BaseDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for Action

  # ===========================================================================
  # :section: Definitions shared with ActionsDecorator
  # ===========================================================================

  public

  module SharedPathMethods
    include BaseDecorator::SharedPathMethods
  end

  module SharedGenericMethods
    include BaseDecorator::SharedGenericMethods
  end

  module SharedInstanceMethods
    include BaseDecorator::SharedInstanceMethods
    include SharedPathMethods
    include SharedGenericMethods
  end

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

class ActionDecorator

  include SharedDefinitions

end

__loading_end(__FILE__)
