# app/controllers/artifact_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ArtifactController
#
# @see ArtifactHelper
#
# == Usage Notes
# The abilities to retrieve or modify artifacts (instances of remediated
# content) is dependent on the role(s) of the authenticated user.
#
class ArtifactController < ApplicationController

  include ApiConcern
  include UserConcern
  include PaginationConcern

  include ArtifactHelper

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
  before_action { @bookshare_id = params[:bookshareId] || params[:id] }
  before_action { @format = params[:type] || Api::FormatType.new.default }

  append_around_action :session_update

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin # TODO: all artifacts? Probably not...
  # == GET /artifact
  # List all artifacts.
  #
  def index
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
    opt  = pagination_setup
    list = @api.get_organization_members(**opt)
    page_items(list.userAccounts)
    total_items(list.totalResults)
    next_page(next_page_path(list, opt))
  end
=end

  # == GET /artifact/:id
  # == GET /artifact/:bookshareId/:type
  # Download an artifact of the indicated Bookshare format type.
  #
  def show
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
    result   = @api.download_title(bookshareId: @bookshare_id, format: @format)
    complete = result.key.to_s.casecmp('COMPLETED').zero?
    dl_link  = complete && result.messages.first
    redirect_to dl_link if dl_link.present?
  end

  # == GET /artifact/new[?id=:id]
  # == GET /artifact/new[?bookshareId=:bookshareId]
  # Add metadata for a new artifact.
  #
  def new
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
  end

  # == POST /artifact/:id
  # == POST /artifact/:bookshareId
  # Upload a new artifact.
  #
  def create
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
  end

  # == GET /artifact/:id/edit
  # == GET /artifact/:bookshareId/edit
  # Modify metadata of an existing artifact entry.
  #
  def edit
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
  end

  # == PUT   /artifact/:id
  # == PATCH /artifact/:id
  # == PUT   /artifact/:bookshareId
  # == PATCH /artifact/:bookshareId
  # Upload a replacement for an existing artifact.
  #
  def update
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
  end

  # == DELETE /artifact/:id
  # == DELETE /artifact/:bookshareId
  # Remove an existing artifact entry.
  #
  def destroy
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
  end

end

__loading_end(__FILE__)
