# app/decorators/search_calls_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/search_call" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<SearchCall>]
#
class SearchCallsDecorator < BaseCollectionDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of SearchCallDecorator

  # ===========================================================================
  # :section: BaseCollectionDecorator::Table overrides
  # ===========================================================================

  public

  # Render search calls as a table.
  #
  # @param [Boolean] extended         If *true*, indicate that this is the
  #                                     "extended" version of the table which
  #                                     replaces columns holding JSON data with
  #                                     columns holding each JSON sub-field.
  # @param [Hash]    opt              Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @note This hasn't been updated since the conversion to Postgres.
  #
  def table(extended: false, **opt)
    prepend_css!(opt, 'extended') if extended
    super(**opt)
  end

end

__loading_end(__FILE__)
