# app/models/concerns/record/authorizable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Add role-based authorization to an ActiveRecord class.
#
module Record::Authorizable

  extend ActiveSupport::Concern

  include Record

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The list of record types that are subject to role-based authorization.
  #
  # @return [Array<Class>]
  #
  def authorizable_classes
    [].tap do |result|
      ObjectSpace.each_object(Class) do |c|
        next unless c.superclass == ApplicationRecord
        result << c if c.ancestors.include?(Record::Authorizable)
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods
    include Record::Authorizable
    # TODO: Record::Authorizable::ClassMethods ???
  end

  # Methods which are only appropriate if the including class is an
  # ApplicationRecord.
  #
  module InstanceMethods
    include Record::Authorizable
    # TODO: Record::Authorizable::InstanceMethods ???
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    # =========================================================================
    # :section: Authorization
    # =========================================================================

    resourcify

  end

end

__loading_end(__FILE__)
