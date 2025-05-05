# app/controllers/concerns/download_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for download events.
#
module DownloadConcern

  extend ActiveSupport::Concern

  include ApplicationHelper

  include ModelConcern

  # ===========================================================================
  # :section: ModelConcern overrides
  # ===========================================================================

  public

  # Extract POST parameters that are usable for creating/updating a download
  # event record instance.
  #
  # @return [Hash]
  #
  def current_post_params
    super do |prm|
      prm[:user_id] ||= current_user&.id
    end
  end

  # Option keys involved in filtering record searches.
  #
  # @return [Array<Symbol>]
  #
  def find_or_match_keys
    super(:source, :publisher, :start_date, :end_date)
  end

  # ===========================================================================
  # :section: OptionsConcern overrides
  # ===========================================================================

  protected

  # Create an Options instance from the current parameters.
  #
  # @return [Download::Options]
  #
  def get_model_options
    Download::Options.new(request_parameters)
  end

  # ===========================================================================
  # :section: PaginationConcern overrides
  # ===========================================================================

  public

  # Create a Paginator for the current controller action.
  #
  # @param [Class<Paginator>] paginator  Paginator class.
  # @param [Hash]             opt        Passed to super.
  #
  # @return [Download::Paginator]
  #
  def pagination_setup(paginator: Download::Paginator, **opt)
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
