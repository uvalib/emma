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

  include ApiConcern
  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern

  include MemberHelper

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :authenticate_user!
  before_action :update_user

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
    __debug { "MEMBER #{__method__} | params = #{params.inspect}" }
    opt   = pagination_setup
    @list = api.get_organization_members(**opt)
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
    __debug { "MEMBER #{__method__} | params = #{params.inspect}" }
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
    __debug { "MEMBER #{__method__} | params = #{params.inspect}" }
  end

  # == POST /member/:id
  # Create an entry for a new organization member.
  #
  def create
    __debug { "MEMBER #{__method__} | params = #{params.inspect}" }
  end

  # == GET /member/:id/edit
  # Modify metadata of an existing organization member entry.
  #
  def edit
    __debug { "MEMBER #{__method__} | params = #{params.inspect}" }
  end

  # == PUT   /member/:id
  # == PATCH /member/:id
  # Update the entry for an existing organization member.
  #
  def update
    __debug { "MEMBER #{__method__} | params = #{params.inspect}" }
  end

  # == DELETE /member/:id
  # Remove an existing organization member entry.
  #
  def destroy
    __debug { "MEMBER #{__method__} | params = #{params.inspect}" }
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [ApiUserAccountList, nil] list
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#index_values
  #
  def index_values(list = @list)
    { members: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [ApiMyAccountSummary, nil]     item
  # @param [ApiMyAccountPreferences, nil] pref
  # @param [ApiTitleDownloadList, nil]    hist
  # @param [Symbol]                       as
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  def show_values(item = @item, pref = @preferences, hist = @history, as: nil)
    { member: super(details: item, preferences: pref, history: hist, as: as) }
  end

end

__loading_end(__FILE__)
