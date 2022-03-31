# app/models/upload/paginator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class Upload::Paginator < Paginator

  # ===========================================================================
  # :section: Paginator overrides
  # ===========================================================================

  public

  def initialize(controller = nil, **opt)
    super
    @initial_parameters.except!(FORM_PARAMS)
  end

  # Finish setting of pagination values based on the result list and original
  # URL parameters.
  #
  # @param [Hash{Symbol=>Any}] result   NOTE: different than super
  # @param [Hash]              opt
  #
  # @return [void]
  #
  def finalize(result, **opt)
    first, last, page = result.values_at(:first, :last, :page)
    self.page_items   = result[:list]
    self.page_size    = result[:limit]
    self.page_offset  = result[:offset]
    self.total_items  = result[:total]
    self.next_page    = (url_for(opt.merge(page: (page + 1))) unless last)
    self.prev_page    = (url_for(opt.merge(page: (page - 1))) unless first)
    self.first_page   = (url_for(opt.except(*PAGE_PARAMS))    unless first)
    self.prev_page    = first_page if page == 2
  end

end

__loading_end(__FILE__)
