# app/controllers/member_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle Bookshare-only "/member" pages.
#
# @see MemberDecorator
# @see MembersDecorator
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

  # Undo the over-encoding required in MemberDecorator#link.
  # noinspection RubyMismatchedArgumentType
  before_action do
    @account_id = params[:userAccountId] || params[:username] || params[:id]
    @account_id &&= CGI.unescape(@account_id)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  respond_to :html, :json, :xml

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /member
  #
  # List all organization members.
  #
  # @see #member_index_path           Route helper
  # @see BookshareService::Request::Organization#get_my_organization_members
  #
  def index
    __debug_route
    err   = nil
    @page = pagination_setup
    opt   = @page.initial_parameters
    b_opt = opt.except(:format)
    @list = bs_api.get_my_organization_members(**b_opt)
    err   = @list.exec_report if @list.error?
    @page.finalize(@list, :userAccounts, **opt)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values(item: :member) }
    end
  rescue => error
    err = error
  ensure
    failure_status(err)
  end

  # == GET /member/:id
  #
  # Display details of an existing organization member.
  #
  # @see #member_path                 Route helper
  # @see UserConcern#get_account_details
  #
  def show
    __debug_route
    err = nil
    @item, @preferences, @history = get_account_details(id: @account_id)
    err = "Account #{@account_id}: no information" if @item.nil?
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values(nil, as: :array) }
    end
  rescue => error
    err = error
  ensure
    failure_status(err)
  end

  # == GET /member/new[?id=:id]
  #
  # Add metadata for a new organization member.
  #
  # @see #new_member_path             Route helper
  #
  def new
    __debug_route
  end

  # == POST /member/:id
  #
  # Create an entry for a new organization member.
  #
  # @see #member_path                 Route helper
  #
  def create
    __debug_route
  end

  # == GET /member/:id/edit
  #
  # Modify metadata of an existing organization member entry.
  #
  # @see #edit_member_path            Route helper
  #
  def edit
    __debug_route
  end

  # == PUT   /member/:id
  # == PATCH /member/:id
  #
  # Update the entry for an existing organization member.
  #
  # @see #member_path                 Route helper
  #
  def update
    __debug_route
  end

  # == DELETE /member/:id
  #
  # Remove an existing organization member entry.
  #
  # @see #member_path                 Route helper
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
  # @param [Bs::Message::UserAccountList] list
  # @param [Hash]               opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list, **opt)
    opt.reverse_merge!(wrap: :members)
    super(list, **opt)
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Hash, nil] result
  # @param [Hash]      opt
  #
  # @return [Hash{Symbol=>Hash,Array}]
  #
  def show_values(result = nil, **opt)
    opt.reverse_merge!(name: :member)
    result ||= { details: @item, preferences: @preferences, history: @history }
    super(result, **opt)
  end

end

__loading_end(__FILE__)
