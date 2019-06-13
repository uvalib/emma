# app/controllers/edition_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# EditionController
#
# @see EditionHelper
#
# == Usage Notes
# The abilities to retrieve or modify editions (instances of remediated
# content) is dependent on the role(s) of the authenticated user.
#
class EditionController < ApplicationController

  include ApiConcern
  include UserConcern
  include PaginationConcern

  include EditionHelper

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  prepend_before_action :session_check
  before_action :authenticate_user!, except: %i[index show]

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  before_action :update_user
  authorize_resource

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :initialize_service
  before_action { @series_id  = params[:seriesId]  || params[:id] }
  before_action { @edition_id = params[:editionId] || params[:id] }
  before_action { @format     = params[:type] || Api::FormatType.new.default }

  append_around_action :session_update

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /edition?seriesId=:seriesId[&editionId=:editionId]
  # List all editions for a periodical.
  #
  def index
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
    opt  = pagination_setup
    list = @api.get_periodical_editions(seriesId: @series_id, **opt)
    page_items(list.periodicalEditions)
    total_items(list.totalResults)
    next_page(next_page_path(list, opt))
  end

  # == GET /edition/:edition_id?seriesId=:seriesId
  # Download a periodical edition.
  #
  def show
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
    api_opt = {
      seriesId:  @series_id,
      editionId: @edition_id,
      format:    @format
    }
    result   = @api.download_periodical_edition(api_opt)
    complete = result.key.to_s.casecmp('COMPLETED').zero?
    dl_link  = complete && result.messages.first
    redirect_to dl_link if dl_link.present?
  end

  # == GET /edition/new[?id=:id]
  # == GET /edition/new[?bookshareId=:bookshareId]
  # Add metadata for a new edition.
  #
  def new
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
  end

  # == POST /edition/:id
  # == POST /edition/:bookshareId
  # Upload a new edition.
  #
  def create
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
  end

  # == GET /edition/:id/edit
  # == GET /edition/:bookshareId/edit
  # Modify metadata of an existing edition entry.
  #
  def edit
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
  end

  # == PUT   /edition/:id
  # == PATCH /edition/:id
  # == PUT   /edition/:bookshareId
  # == PATCH /edition/:bookshareId
  # Upload a replacement for an existing edition.
  #
  def update
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
  end

  # == DELETE /edition/:id
  # == DELETE /edition/:bookshareId
  # Remove an existing edition entry.
  #
  def destroy
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
  end

end

__loading_end(__FILE__)
