# app/services/bookshare_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Common
#
module BookshareService::Common

  include ApiService::Common

  include BookshareService::Properties
  include BookshareService::Identity

  # ===========================================================================
  # :section: ApiService::Common overrides
  # ===========================================================================

  protected

  # Add service-specific API options.
  #
  # @param [Hash, nil] params         Default: @params.
  #
  # @return [Hash]                    New API parameters.
  #
  def api_options(params = nil)
    super.tap do |result|
      result[:limit] = MAX_LIMIT if result[:limit].to_s == 'max'
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.send(:include, BookshareService::Definition)
  end

end

__loading_end(__FILE__)
