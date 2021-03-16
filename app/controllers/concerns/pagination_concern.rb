# app/controllers/concerns/pagination_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for managing pagination.
#
module PaginationConcern

  extend ActiveSupport::Concern

  included do |base|

    __included(base, 'PaginationConcern')

    # Non-functional hints for RubyMine type checking.
    # :nocov:
    unless ONLY_FOR_DOCUMENTATION
      include AbstractController::Callbacks::ClassMethods
      include PaginationConcern
    end
    # :nocov:

    # =========================================================================
    # :section: Callbacks
    # =========================================================================

    before_action :cleanup_pagination, only: %i[index]

  end

  include Emma::Common
  include ParamsHelper
  include SearchTermsHelper
  include PaginationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Pagination setup.
  #
  # @param [ActionController::Parameters, Hash, nil] opt  Default: `params`.
  #
  # @option opt [Symbol] :controller
  #
  # @return [Hash{Symbol=>String}]    URL parameters.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def pagination_setup(opt = nil)

    opt = url_parameters(opt)

    # Remove pagination parameters and return if the current controller does
    # not support pagination.
    # noinspection RubyYardReturnMatch
    return opt.except!(:limit, *PAGINATION_KEYS) if page_size.zero?

    # Get pagination values.
    limit, page, offset =
      opt.values_at(:limit, :page, :offset).map { |v| v&.to_i }
    limit  ||= page_size
    page   ||= (offset / limit) + 1 if offset
    offset ||= (page - 1) * limit   if page

    # Get first and current page paths; adjust values if currently on the first
    # page of results.
    main_page    = request.path
    path_opt     = { decorate: true, unescape: true }
    mp_opt       = opt.merge(path_opt)
    current_page = make_path(main_page, mp_opt)
    first_page   = main_page
    on_first     = (current_page == first_page)
    unless on_first
      mp_opt     = opt.except(*PAGINATION_KEYS).merge!(path_opt)
      first_page = make_path(main_page, mp_opt)
      on_first   = (current_page == first_page)
    end
    unless on_first
      mp_opt     = opt.except(:limit, *PAGINATION_KEYS).merge!(path_opt)
      first_page = make_path(main_page, mp_opt)
      on_first   = (current_page == first_page)
    end

    # The previous page link is just 'history.back()', however this is special-
    # cased on the second page because of issues observed in Google Chrome.
    prev_page =
      if on_first
        offset = 0
        first_page = nil
      elsif page == 2
        first_page
      elsif local_request?
        :back
      end

    # Set current values for the including controller.
    self.page_size   = limit
    self.page_offset = offset
    self.first_page  = first_page
    self.prev_page   = prev_page

    # Adjust parameters to be transmitted to the Bookshare API.
    if offset&.nonzero?
      opt[:offset] = offset
    else
      opt.delete(:offset)
    end
    opt[:limit] = page_size

    # noinspection RubyYardReturnMatch
    opt

  end

  # Analyze the *list* object to generate the path for the next page of
  # results.
  #
  # @param [Array, #next, #get_link] list
  # @param [Hash]                    url_params For `list.next`.
  #
  # @return [String]                  Path to generate next page of results.
  # @return [nil]                     If there is no next page.
  #
  # @see SearchConcern#next_page_path
  #
  def next_page_path(list: nil, **url_params)
    list ||= @list || self.page_items
    if (start = list.respond_to?(:next) && list.next).present?
      opt = url_params&.dup || {}
      opt[:start]    = start
      opt[:limit]  ||= page_size
      opt[:offset] ||= page_offset
      opt[:offset]  += opt[:limit]
      opt.delete(:limit) if opt[:limit] == default_page_size
      make_path(request.path, opt)
    elsif list.respond_to?(:get_link)
      list.get_link(:next)
    end
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Clean up pagination-related parameters.
  #
  # @return [void]
  #
  def cleanup_pagination
    original_count = request_parameter_count

    # Eliminate :offset if not still paginating.
    if params[:offset].present?
      params.delete(:offset) unless params[:start] || params[:prev_id]
    end

    # If parameters were removed, redirect to the corrected URL.
    will_redirect unless request_parameter_count == original_count
  end

end

__loading_end(__FILE__)
