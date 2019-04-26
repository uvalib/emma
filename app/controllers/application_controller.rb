# app/controllers/application_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApplicationController
#
class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception

  add_flash_types :error, :success

  # Include the Emma constants in the compiled *.html.erb files.
  [Emma, Emma::Constants].each do |mod|
    ActionView::CompiledTemplates.send(:include, mod)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # TODO: ???

end

__loading_end(__FILE__)
