# app/controllers/search_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchController
#
# @see SearchHelper
#
class SearchController < ApplicationController

  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern
  include SearchConcern

  include IsbnHelper
  include IssnHelper
  include OclcHelper

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  #before_action :update_user

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action { @title_id = params[:titleId] || params[:id] }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /search
  # Perform a search through the EMMA Federated Search API.
  #
  def index
    __debug { "SEARCH #{__method__} | params = #{params.inspect}" }
    opt = pagination_setup
    opt[:q] ||= '*' # A "null search" by default.
    @list = api.get_records(**opt)
    self.page_items  = @list.records
    #self.total_items = @list.totalResults
    #self.next_page   = next_page_path(@list, opt)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # == GET /search/:id
  # Display details of an existing catalog title.
  #
  def show
    __debug { "SEARCH #{__method__} | params = #{params.inspect}" }
    @item = api.get_record(titleId: @title_id)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Search::SearchRecordList, nil] list
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#index_values
  #
  def index_values(list = @list)
    { records: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Search::Record::MetadataRecord, nil] item
  # @param [Symbol]                      as     Unused.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  def show_values(item = @item, as: nil)
    { records: item }
  end

end

__loading_end(__FILE__)
