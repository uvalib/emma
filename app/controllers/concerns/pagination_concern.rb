# app/controllers/concerns/pagination_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support for managing pagination.
#
module PaginationConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'PaginationConcern')
  end

  include PaginationHelper

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Pagination setup.
  #
  # @param [ActionController::Parameters, Hash, nil] opt    Default: `#params`.
  #
  # @options opt [Symbol] :controller
  #
  # @return [Hash]                    URL parameters.
  #
  def pagination_setup(opt = params)
    session_section = opt[:controller]&.to_s || 'all'
    ss  = session[session_section] ||= {}
    opt = url_parameters(opt)
    this_page = request.original_fullpath
    page_size(opt[:limit] || ss[:page_size])
    ss['page_offset'] ||= 0
    if ss['prev_page'] == this_page
      ss['prev_page']    = prev_page(nil) # TODO: ???
      ss['page_offset'] -= page_size if ss['page_offset'] >= page_size
    elsif !opt[:start]
      ss['prev_page']    = prev_page(nil)
      ss['page_offset']  = 0
    else
      ss['prev_page']    = prev_page(ss['this_page'])
      ss['page_offset'] += page_size
    end
    ss['this_page'] = this_page
    page_offset(ss['page_offset'])
    first_page(make_path(request_path, opt.except(:start)))
    opt.merge(limit: page_size)
  end

  # Analyze the *list* object to generate the path for the next page of
  # results.
  #
  # @param [Object] list
  # @param [Hash]   url_params
  #
  # @return [String, nil]
  #
  def next_page_path(list, url_params)
    if list.respond_to?(:next) && list.next.present?
      make_path(request.path, url_params.merge(start: list.next))
    elsif list.respond_to?(:get_link)
      list.get_link('next')
    elsif list.respond_to?(:links) && list.links.is_a?(Array)
      raise 'Should use :get_link' # TODO: remove section
      list.links.find { |link|
        break link.href if (link.rel == 'next') && link.href.present?
      }
    end
  end

end

__loading_end(__FILE__)
