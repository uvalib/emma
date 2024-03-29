# app/decorators/enrollments_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/enrollment" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<Enrollment>]
#
class EnrollmentsDecorator < BaseCollectionDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of EnrollmentDecorator

  # ===========================================================================
  # :section: BaseCollectionDecorator overrides
  # ===========================================================================

  public

  # By default, enrollment listings are not :pageable -- that is, all items
  # matching the search criteria are expected to be rendered in a table which
  # is client-side sortable.
  #
  # @param [ActiveRecord::Relation, Paginator, Array, nil] obj
  # @param [Hash]                                          opt
  #
  def initialize(obj = nil, **opt)
    opt[:pageable] = false unless opt.key?(:pageable)
    super
  end

end

__loading_end(__FILE__)
