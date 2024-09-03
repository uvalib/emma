# app/controllers/help_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle "/help" pages.
#
# @see HelpHelper
# @see file:app/views/help/**
#
class HelpController < ApplicationController

  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include HelpConcern

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include AbstractController::Callbacks
    # :nocov:
  end

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # Not applicable.

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :set_help_topic

  # ===========================================================================
  # :section: Formats
  # ===========================================================================

  respond_to :html, :json, :xml

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

  # === GET /help
  #
  # The main help page.
  #
  # @see #help_index_path             Route helper
  #
  def index
    return redirect_to help_path(id: @topic) if @topic.present?
    __log_activity
    __debug_route
    @list = help_topics
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  rescue => error
    failure_status(error)
  end

  # === GET /help/:topic
  # === GET /help?topic=:topic
  #
  # The topic help page.
  #
  # @see #help_path                   Route helper
  #
  def show
    __log_activity
    __debug_route
    raise 'No topic specified'          if @topic.blank?
    raise "#{@topic}: not a help topic" if HELP_ENTRY[@topic].blank?
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  rescue => error
    failure_status(error)
  end

end

__loading_end(__FILE__)
