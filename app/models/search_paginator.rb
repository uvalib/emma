# app/models/search_paginator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class SearchPaginator < Paginator

  # ===========================================================================
  # :section: Paginator overrides
  # ===========================================================================

  public

  # Finish setting of pagination values based on the result list and original
  # URL parameters.
  #
  # @param [Api::Record, Array, Hash] result
  # @param [Symbol, nil]              as      Only for Api::Record or Array.
  # @param [Hash]                     opt
  #
  # @return [Array]
  #
  #--
  # === Variations
  #++
  #
  # @overload finalize(result, **opt)
  #   Generally for Record-related models.
  #   @param [Hash{Symbol=>*}]    result
  #   @param [Hash]               opt     Passed to #url_for.
  #   @return [Array]                     The value of #page_items.
  #
  # @overload finalize(result, as: nil, **opt)
  #   Generally for other models (e.g. API-related).
  #   @param [Api::Record, Array] result
  #   @param [Symbol, nil]        as      Method to extract items from result.
  #   @param [Hash]               opt     Passed to #next_page_path.
  #   @return [Array]                     The value of #page_items.
  #
  def finalize(result, as: nil, **opt)
    # noinspection RubyMismatchedArgumentType
    if result.is_a?(Hash)
      super(result, **opt)
    else
      self.page_items   = as && result.try(as) || result
      self.page_records = record_count(result)
      self.total_items  = item_count(result)
      self.next_page    = next_page_path(list: result, **opt)
      self.page_items
    end
  end

  # ===========================================================================
  # :section: Paginator overrides
  # ===========================================================================

  public

  # Analyze the *list* object to generate the path for the next page of
  # results.
  #
  # @param [Search::Message::SearchTitleList, Array<Search::Record::MetadataRecord>, nil] list
  # @param [Hash, nil] url_params     Current request parameters.
  #
  # @return [String]                  Path to generate next page of results.
  # @return [nil]                     If there is no next page.
  #
  def next_page_path(list: nil, **url_params)
    items = list&.try(:records) || list || page_items
    return if (items.size < page_size) || (last = items.last).blank?

    # General pagination parameters.
    prm    = url_parameters(url_params)
    page   = positive(prm.delete(:page))
    offset = positive(prm.delete(:offset))
    limit  = positive(prm.delete(:limit))
    size   = limit || page_size
    if offset && page
      offset = nil if offset == ((page - 1) * size)
    elsif offset
      page   = (offset / size) + 1
      offset = nil
    else
      page ||= 1
    end
    prm[:page]   = page   + 1    if page
    prm[:offset] = offset + size if offset
    prm[:limit]  = limit         if limit && (limit != default_page_size)

    # Parameters specific to the EMMA Unified Search API.
    title = date = nil
    case prm[:sort]&.to_sym
      when :title               then title = last.dc_title
      when :sortDate            then date  = last.emma_sortDate
      when :publicationDate     then date  = last.emma_publicationDate
      when :lastRemediationDate then date  = last.rem_remediationDate
      else                           prm.except!(:prev_id, :prev_value)
    end
    if title || date
      prm[:prev_id]    = url_escape(last.emma_recordId)
      prm[:prev_value] = url_escape(title || IsoDay.cast(date).to_s)
    end

    make_path(request.path, **prm)
  end

end

__loading_end(__FILE__)
