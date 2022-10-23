# app/decorators/search_title_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for hierarchical result "/search" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Search::Record::TitleRecord]
#
class SearchTitleDecorator < SearchDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for search: Search::Record::TitleRecord

  # ===========================================================================
  # :section: SearchDecorator overrides
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_item(pairs: nil, **opt)
    if present?
      # noinspection RailsParamDefResolve
      if relevancy_scores?
        added = object.try(:get_scores, precision: 2, all: true) || {}
        added[:sort_date] = object.try(:emma_sortDate).presence
        added[:pub_date]  = object.try(:emma_publicationDate).presence
        added[:rem_date]  = object.try(:rem_remediationDate).presence
        added.transform_values! { |score| score || EMPTY_VALUE }
        pairs = pairs&.merge(added) || added
      end
      if title_results?
        opt.delete(:'aria-rowindex')
        opt[:outer]    = (opt[:outer]&.dup || {}).merge!('aria-rowindex': nil)
        opt[:render] ||= :render_field_hierarchy
      end
      opt[:pairs] = pairs || {} if object.aggregate?
    end
    super(**opt)
  end

  # Include control icons below the entry number.
  #
  # @param [Boolean] edit             If *false* do not add edit controls.
  # @param [Hash]    opt              Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_item_number(edit: true, **opt)
    opt[:toggle] = title_results? unless opt.key?(:toggle)
    super(**opt)
  end

end

__loading_end(__FILE__)
