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

  # Create a Paginator for the current controller action.
  #
  # @param [ApplicationController] ctrlr      Default: calling controller.
  # @param [Class<Paginator>]      paginator  Paginator class.
  # @param [Hash]                  opt        Additions/overrides to `#params`.
  #
  # @return [Paginator]
  #
  def pagination_setup(ctrlr: nil, paginator: Paginator, **opt)
    unless (ctrlr ||= self).is_a?(ApplicationController)
      raise "#{__method__}: invalid controller: #{ctrlr.class}"
    end
    opt.reverse_merge!(request_parameters)
    paginator.new(ctrlr, **opt)
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

  end

end

__loading_end(__FILE__)
