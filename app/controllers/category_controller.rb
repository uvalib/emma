# app/controllers/category_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# CategoryController
#
# @see CategoryHelper
#
# == Usage Notes
# Categories can be seen by anyone, including anonymous users.
#
class CategoryController < ApplicationController

  include ApiConcern
  include SessionConcern
  include PaginationConcern

  include CategoryHelper

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  prepend_before_action :session_check

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :initialize_service

  append_around_action :session_update

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /category
  # List all categories.
  #
  def index
    __debug { "CATEGORY #{__method__} | params = #{params.inspect}" }
    opt  = pagination_setup
    list = @api.get_categories(**opt)
    page_items(list.categories)
    total_items(list.totalResults)
    next_page(next_page_path(list, opt))
  end

end

__loading_end(__FILE__)
