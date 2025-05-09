# app/decorators/downloads_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/downloads" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<Download>]
#
class DownloadsDecorator < BaseCollectionDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of DownloadDecorator

  # ===========================================================================
  # :section: BaseCollectionDecorator overrides
  # ===========================================================================

  public

  # Currently download event listings are not :pageable -- that is, all items
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
