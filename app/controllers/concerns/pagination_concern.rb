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

    # Non-functional hints for RubyMine.
    # :nocov:
    unless ONLY_FOR_DOCUMENTATION
      include AbstractController::Callbacks::ClassMethods
    end
    # :nocov:

    # =========================================================================
    # :section: Callbacks
    # =========================================================================

    before_action :cleanup_pagination, only: [:index]

  end

  include Emma::Common
  include ParamsHelper
  include PaginationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Pagination setup.
  #
  # @param [ActionController::Parameters, Hash, nil] opt  Default: `#params`.
  #
  # @option opt [Symbol] :controller
  #
  # @return [Hash{Symbol=>String}]    URL parameters.
  #
  def pagination_setup(opt = nil)

    opt = url_parameters(opt)
    ss  = session_section

    # Clean up the session and return if the current controller does not
    # support pagination.
    if self.page_size.zero?
      keys = %i[limit offset].each { |k| ss.delete(k.to_s) }
      # noinspection RubyYardReturnMatch
      return opt.except(*keys)
    end

    # Get values from parameters or session.
    page_size   = opt[:limit]&.to_i  || ss['limit']&.to_i  || self.page_size
    page_offset = opt[:offset]&.to_i || ss['offset']&.to_i || self.page_offset

    # Get first and current page paths; adjust values if currently on the first
    # page of results.
    current    = make_path(request.original_fullpath)
    main_page  = current.sub(/\?.*$/, '')
    first_page = main_page
    on_first   = (current == first_page)
    unless on_first
      first_page = make_path(main_page, opt.except(:start, :offset))
      on_first   = (current == first_page)
    end
    unless on_first
      first_page = make_path(main_page, opt.except(:start, :offset, :limit))
      on_first   = (current == first_page)
    end
    prev_page  =
      if on_first
        page_offset = 0
        first_page  = nil
      elsif "#{request.referer}/".start_with?(root_url)
        :back
      end

    # Set current values for the including controller.
    self.page_size   = page_size
    self.page_offset = page_offset
    self.first_page  = first_page
    self.prev_page   = prev_page

    # Set session values to be used by the subsequent page.
    ss['limit']  = page_size
    ss['offset'] = page_offset + page_size

    # Adjust parameters to be transmitted to the API.
    opt[:limit] = page_size
    if page_offset.zero?
      opt.delete(:offset)
    else
      opt[:offset] = page_offset
    end

    # noinspection RubyYardReturnMatch
    opt

  end

  # Analyze the *list* object to generate the path for the next page of
  # results.
  #
  # @param [Object]    list
  # @param [Hash, nil] url_params     For `list.next`.
  #
  # @return [String]
  # @return [nil]                     If there is no next page.
  #
  def next_page_path(list, url_params = nil)
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

    # Eliminate :offset if :start is not present.
    if params[:offset].present? && params[:start].blank?
      params.delete(:offset)
    end

    # If parameters were removed, redirect to the corrected URL.
    will_redirect unless request_parameter_count == original_count
  end

end

__loading_end(__FILE__)
