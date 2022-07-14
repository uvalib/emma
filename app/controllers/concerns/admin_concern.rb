# app/controllers/concerns/admin_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for administration.
#
module AdminConcern

  extend ActiveSupport::Concern

  include ApplicationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Administrative pages (except for :index).
  #
  # @type [Array<Symbol>]
  #
  ADMIN_PAGES =
    CONTROLLER_CONFIGURATION[:admin].map { |k, v|
      k if v.is_a?(Hash) && v[:_endpoint] && (k != :index)
    }.compact.freeze

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
