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

  module Methods
    include BaseDecorator::Methods
  end

  module InstanceMethods
    include BaseDecorator::InstanceMethods, Paths, Methods
  end

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
