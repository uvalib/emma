# app/decorators/search_record_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for record result "/search" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Search::Record::MetadataRecord]
#
class SearchRecordDecorator < SearchDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for search: Search::Record::MetadataRecord

  # ===========================================================================
  # :section: SearchDecorator overrides
  # ===========================================================================

  public

  # Include control icons below the entry number.
  #
  # @param [Boolean] edit             If *false*, do not add edit controls.
  # @param [Hash]    opt              Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_item_number(edit: true, **opt)
    opt[:controls] = edit unless opt.key?(:controls)
    super(**opt)
  end

end

__loading_end(__FILE__)
