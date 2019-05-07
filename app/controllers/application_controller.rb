# app/controllers/application_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApplicationController
#
class ApplicationController < ActionController::Base

  include MetricsConcern

  # Include the Emma constants in the compiled *.html.erb files.
  [Emma, Emma::Constants].each do |mod|
    ActionView::CompiledTemplates.send(:include, mod)
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protect_from_forgery with: :exception

  # ===========================================================================
  # :section: Helpers
  # ===========================================================================

  add_flash_types :error, :success

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # TODO: ???

end

__loading_end(__FILE__)
