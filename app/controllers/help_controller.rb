# app/controllers/help_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Help pages.
#
# @see app/views/help
#
class HelpController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include SerializationConcern
  include HelpConcern

  # Non-functional hints for RubyMine.
  # :nocov:
  include AbstractController::Callbacks unless ONLY_FOR_DOCUMENTATION
  # :nocov:

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :set_help_topic

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /help
  # The main help page.
  #
  def index
    return redirect_to help_path(id: @topic) if @topic.present?
    __debug_route
    @list = help_topics
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # == GET /help/:topic
  # == GET /help?topic=:topic
  # The topic help page.
  #
  def show
    __debug_route
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

  # Response values for serializing the index page to JSON or XML.
  #
  # @param [*, nil] list
  #
  # @return [Hash{Symbol=>Array,Hash}]
  #
  def index_values(list = @list)
    { help: list.reduce({}) { |hash, topic| hash.merge!(show_values(topic)) } }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Symbol] topic
  #
  # @return [Hash{Symbol=>*}]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  def show_values(topic = @topic, **)
    { topic => get_help_entry(topic) }
  end

end

__loading_end(__FILE__)
