# app/services/lookup_service/crossref/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LookupService::Crossref::Common
#
module LookupService::Crossref::Common

  include LookupService::RemoteService::Common

  include LookupService::Crossref::Properties

  # ===========================================================================
  # :section: ApiService::Common overrides
  # ===========================================================================

  protected

  # Crossref-specific parameter additions.
  #
  # @param [Symbol] meth              Calling method.
  # @param [Hash]   opt               Passed to super.
  #
  # @return [Hash]
  #
  def get_parameters(meth, **opt)
    super.tap do |result|

      # Add requester identification to be in the "polite pool".
      result[:mailto] ||= api_user

      # If :select is present, ensure it is in the proper form, translating
      # underscored attribute names into the expected dasherized form.
      if result.key?(:select)
        flds   = result[:select]
        flds &&= flds.is_a?(TrueClass) ? SELECT_ELEMENTS : select_list(*flds)
        if flds.present?
          result[:select] = flds.join(',')
        else
          result.delete(:select)
        end
      end

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
    base.include(LookupService::Crossref::Definition)
  end

end

__loading_end(__FILE__)
