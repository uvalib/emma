# app/controllers/member_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# MemberController
#
# @see MemberHelper
#
class MemberController < ApplicationController

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
    @user_id = params[:username] || params[:id]
    @user_id &&= CGI.unescape(@user_id)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /member
  # List all organization members.
  #
  def index
    __debug_route('MEMBER')
    opt   = pagination_setup
    @list = api.get_my_organization_members(**opt)
    self.page_items  = @list.userAccounts
    self.total_items = @list.totalResults
    self.next_page   = next_page_path(@list, opt)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # == GET /member/:id
  # Display details of an existing organization member.
  #
  def show
    __debug_route('MEMBER')
    @item, @preferences, @history = get_account_details(id: @user_id)
    respond_to do |format|
      format.html
      format.json { render_json show_values(as: :hash)  }
      format.xml  { render_xml  show_values(as: :array) }
    end
  end

  # == GET /member/new[?id=:id]
  # Add metadata for a new organization member.
  #
  def new
    __debug_route('MEMBER')
  end

  # == POST /member/:id
  # Create an entry for a new organization member.
  #
  def create
    __debug_route('MEMBER')
  end

  # == GET /member/:id/edit
  # Modify metadata of an existing organization member entry.
  #
  def edit
    __debug_route('MEMBER')
  end

  # == PUT   /member/:id
  # == PATCH /member/:id
  # Update the entry for an existing organization member.
  #
  def update
    __debug_route('MEMBER')
  end

  # == DELETE /member/:id
  # Remove an existing organization member entry.
  #
  def destroy
    __debug_route('MEMBER')
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
  # This method overrides:
  # @see SerializationConcern#index_values
  #
  def index_values(list = @list)
    { members: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @overload show_values(as: :array)
  #   @return [Array]
  #
  # @overload show_values(as: :hash)
  #   @return [Hash{Symbol=>Hash}]
  #
  # @overload show_values
  #   @return [Hash{Symbol=>Hash}]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  def show_values(as: nil)
    result = { details: @item, preferences: @preferences, history: @history }
    { member: super(**result, as: as) }
  end

end

__loading_end(__FILE__)
