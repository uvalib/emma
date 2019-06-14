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
  include PaginationConcern

  include MemberHelper

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  prepend_before_action :session_check
  before_action :authenticate_user!

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  before_action :update_user
  authorize_resource

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :initialize_service
  before_action { @user_id = params[:username] || params[:id] }

  append_around_action :session_update

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /member
  # List all organization members.
  #
  def index
    __debug { "MEMBER #{__method__} | params = #{params.inspect}" }
    opt  = pagination_setup
    opt.delete(:limit) # TODO: testing to see whether this screws up Bookshare
    list = @api.get_organization_members(**opt)
    page_items(list.userAccounts)
    total_items(list.totalResults)
    next_page(next_page_path(list, opt))
  end

  # == GET /member/:id
  # Display details of an existing organization member.
  #
  def show
    __debug { "MEMBER #{__method__} | params = #{params.inspect}" }
    @item = @api.get_account(user: @user_id)
    @pref = @api.get_my_preferences
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

end

__loading_end(__FILE__)