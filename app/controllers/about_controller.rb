# app/controllers/data_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class AboutController < ApplicationController

  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include AboutConcern

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # Not applicable.

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  # None

  # ===========================================================================
  # :section: Formats
  # ===========================================================================

  respond_to :html, :json, :xml

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

  # === GET /about
  #
  # Application information main page.
  #
  # @see #about_index_path            Route helper
  #
  def index
    __log_activity
    __debug_route
  end

  # An endpoint is defined for each configured page that hasn't already been
  # defined here.  Pages that are not just redirects should have a template in
  # "/app/views/about".
  #
  # @type [Array<Symbol>]
  #
  PAGES = ABOUT_PAGES
  PAGES.excluding(*instance_methods(false)).each do |page|
    define_method(page) do
      __log_activity
      __debug_route
    end
  end

end

__loading_end(__FILE__)
