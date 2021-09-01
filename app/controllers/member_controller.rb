# app/controllers/member_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle Bookshare-only "/member" pages.
#
# @see MemberHelper
# @see file:app/views/member/**
#
# @note These endpoints are not currently presented as a part of EMMA.
#
class MemberController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include PaginationConcern
  include SerializationConcern
  include BookshareConcern

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include AbstractController::Callbacks
    # :nocov:
  end

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_user!

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  # Undo the over-encoding required in MemberHelper#member_link.
  before_action do
    @account_id = params[:userAccountId] || params[:username] || params[:id]
    @account_id &&= CGI.unescape(@account_id)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /member
  #
  # List all organization members.
  #
  # @see BookshareService::Request::Organization#get_my_organization_members
  #
  def index
    __debug_route
    opt   = pagination_setup
    @list = bs_api.get_my_organization_members(**opt)
    pagination_finalize(@list, :userAccounts, **opt)
    flash_now_alert(@list.exec_report) if @list.error?
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # == GET /member/:id
  #
  # Display details of an existing organization member.
  #
  # @see UserConcern#get_account_details
  #
  def show
    __debug_route
    @item, @preferences, @history = get_account_details(id: @account_id)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values(nil, as: :array) }
    end
  end

  # == GET /member/new[?id=:id]
  #
  # Add metadata for a new organization member.
  #
  def new
    __debug_route
  end

  # == POST /member/:id
  #
  # Create an entry for a new organization member.
  #
  def create
    __debug_route
  end

  # == GET /member/:id/edit
  #
  # Modify metadata of an existing organization member entry.
  #
  def edit
    __debug_route
  end

  # == PUT   /member/:id
  # == PATCH /member/:id
  #
  # Update the entry for an existing organization member.
  #
  def update
    __debug_route
  end

  # == DELETE /member/:id
  #
  # Remove an existing organization member entry.
  #
  def destroy
    __debug_route
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [ApiUserAccountList] list
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list)
    { members: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Hash, nil]   result
  # @param [Symbol, nil] as           Either :hash or :array if given.
  #
  # @return [Hash{Symbol=>Hash,Array}]
  #
  def show_values(result = nil, as: nil)
    result ||= { details: @item, preferences: @preferences, history: @history }
    { member: super(result, as: as) }
  end

end

__loading_end(__FILE__)
