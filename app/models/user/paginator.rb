# app/models/user/paginator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Parameters for pagination of lists of User records.
#
class User::Paginator < Paginator

  # ===========================================================================
  # :section: Paginator overrides
  # ===========================================================================

  public

  # By default, account listings are not :pageable -- that is, all items
  # matching the search criteria are expected to be rendered in a table which
  # is client-side sortable.
  #
  # @param [ApplicationController, nil] ctrlr
  # @param [Hash]                       opt     Passed to super.
  #
  def initialize(ctrlr = nil, **opt)
    opt[:action]  = base_action(opt[:action]) if opt[:action]
    opt[:disabled] = true unless opt.key?(:disabled)
    super
  end

end

__loading_end(__FILE__)
