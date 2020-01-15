# app/controllers/search_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchController
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

  # Non-functional hints for RubyMine.
  # :nocov:
  include AbstractController::Callbacks unless ONLY_FOR_DOCUMENTATION
  # :nocov:

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # before_action :update_user

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
    __debug_route('SEARCH')
    opt = pagination_setup
    if true # TODO: remove - testing
      development_notice(
        'This page currently shows simulated results of a federated search ' \
          'for "<strong>The Works of Edgar Allan Poe</strong>".',
        '(This is actually only a partial list using hand-crafted, embedded ' \
          'data; the actual search result would include several hundred ' \
          'more entries for this title).',
        '<a href="/search/example" style="font-weight:bold">Click here</a> ' \
          'to see a single template record which shows all of the fields ' \
          'currently defined by the API.'
      )
      @list = api.get_example_records(**opt)
      self.page_items  = @list.records
      self.total_items = @list.records.size
    else # TODO: restore
      opt[:q] ||= '*' # A "null search" by default.
      @list = api.get_records(**opt)
      self.page_items  = @list.records
    # self.total_items = @list.totalResults       # TODO: Federated Search API
    # self.next_page = next_page_path(@list, opt) # TODO: Federated Search API
    end
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
    __debug_route('SEARCH')
    if @title_id == 'example' # TODO: remove - testing
      development_notice(
        'This page displays all of the possible fields defined for each' \
          'federated search results record.',
        'Click on "Search" above to see a simulated example of federated ' \
          ' search results.'
      )
      @item = api.get_example_records(example: :template).records.first
    else # TODO: restore
      @item = api.get_record(titleId: @title_id)
    end
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  end

  # == GET /search/detail?repositoryId=xxx[&repository=xxx]&fmt={brf|daisy|...}
  # == GET /search/:fmt?repositoryId=xxx[&repository=xxx]
  # Display details of a file from a repository.
  #
  def file_detail
    __debug_route('SEARCH')
    locals = get_file_details(params)
    respond_to do |format|
      format.html { render locals: locals }
      format.json { render_json show_values(locals) }
      format.xml  { render_xml  show_values(locals) }
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
  # @return [Hash{Symbol=>Hash}]
  #
  # This method overrides:
  # @see SerializationConcern#index_values
  #
  def index_values(list = @list)
    { records: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Search::Record::MetadataRecord, Hash] item
  #
  # @return [Hash{Symbol=>Hash}]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  def show_values(item = @item)
    { records: normalize_keys(item) }
  end

  # ===========================================================================
  # :section: TODO: remove - testing
  # ===========================================================================

  protected

  # Display a flash message during development.
  #
  # @param [Array] lines
  #
  # @return [void]
  #
  def development_notice(*lines) # TODO: remove - testing
    lead  = '<strong>The Federated Search API is not yet implemented.</strong>'
    lines = lines.unshift(lead).flatten.compact.join("<br/>" * 2).html_safe
    flash.now[:notice] = %Q(<span class="box">#{lines}</span>).html_safe
  end

end

__loading_end(__FILE__)
