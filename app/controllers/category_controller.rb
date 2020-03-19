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

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern
  include BookshareConcern

  # Non-functional hints for RubyMine.
  # :nocov:
  include AbstractController::Callbacks unless ONLY_FOR_DOCUMENTATION
  # :nocov:

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  # None

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /category
  # List all categories.
  #
  def index
    __debug_route
    opt   = pagination_setup
    @list = api.get_categories(**opt)
    self.page_items  = @list.categories
    self.total_items = @list.totalResults
    self.next_page   = next_page_path(@list, opt)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [ApiCategoriesList] list
  #
  # @return [Hash{Symbol=>Hash}]
  #
  # This method overrides:
  # @see SerializationConcern#index_values
  #
  def index_values(list = @list)
    { categories: super(list) }
  end

end

__loading_end(__FILE__)
