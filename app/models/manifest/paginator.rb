# app/models/manifest/paginator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class Manifest::Paginator < Paginator

  # ===========================================================================
  # :section: Paginator overrides
  # ===========================================================================

  public

  def initialize(ctrlr = nil, **opt)
    super
    @initial_parameters.except!(*FORM_PARAMS)
  end

  # Finish setting of pagination values based on the result list and original
  # URL parameters.
  #
  # @param [Hash{Symbol=>*}] result
  # @param [Hash]            opt
  #
  # @return [Array]
  #
  def finalize(result, **opt)
    raise "#{result.class}: not a Hash" unless result.is_a?(Hash)
    super
  end

end

__loading_end(__FILE__)
