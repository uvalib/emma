# app/controllers/concerns/pagination_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for managing pagination.
#
module PaginationConcern

  extend ActiveSupport::Concern

  include ParamsConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Pagination information for the current page.
  #
  # @return [Paginator]
  #
  def paginator(*)
    @paginator ||= pagination_setup
  end

  # Create a Paginator for the current controller action.
  #
  # @param [ApplicationController] ctrlr      Default: calling controller.
  # @param [Class<Paginator>]      paginator  Paginator class.
  # @param [Hash]                  opt        Additions/overrides to `#params`.
  #
  # @return [Paginator]
  #
  def pagination_setup(ctrlr: nil, paginator: Paginator, **opt)
    ctrlr ||= self
    paginator.new(ctrlr, **request_parameters, **opt)
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
    original_count = params.keys.size

    # Eliminate :offset if not still paginating.
    if params[:offset].present?
      params.delete(:offset) unless params[:start] || params[:prev_id]
    end

    # If parameters were removed, redirect to the corrected URL.
    will_redirect unless params.keys.size == original_count
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include AbstractController::Callbacks::ClassMethods
      include PaginationConcern
      # :nocov:
    end

    # =========================================================================
    # :section: Callbacks
    # =========================================================================

    if respond_to?(:before_action)
      before_action :cleanup_pagination, only: %i[index]
    end

    # =========================================================================
    # :section: Helpers
    # =========================================================================

    helper_method :paginator if respond_to?(:helper_method)

  end

end

__loading_end(__FILE__)
