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
  include SerializationConcern
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
  # :section:
  # ===========================================================================

  respond_to :html, :json, :xml

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /help
  #
  # The main help page.
  #
  # @see #help_index_path             Route helper
  # @see HelpHelper#help_topics
  #
  def index
    err = nil
    # noinspection RubyMismatchedArgumentType
    return redirect_to help_path(id: @topic) if @topic.present?
    __debug_route
    @list = help_topics
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  rescue => error
    err = error
  ensure
    failure_response(err) if err
  end

  # == GET /help/:topic
  # == GET /help?topic=:topic
  #
  # The topic help page.
  #
  # @see #help_path                   Route helper
  #
  def show
    __debug_route
    err = ('No topic specified' if @topic.nil?)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  rescue => error
    err = error
  ensure
    failure_response(err) if err
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for serializing the index page to JSON or XML.
  #
  # @param [Array] list
  # @param [Hash]  opt
  #
  # @return [Hash{Symbol=>Array,Hash}]
  #
  def index_values(list = @list, **opt)
    opt.reverse_merge!(wrap: :help)
    result = list.reduce({}) { |hash, topic| hash.merge!(show_values(topic)) }
    super(result, **opt)
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Symbol] topic
  # @param [Hash]   opt
  #
  # @return [Hash{Symbol=>*}]
  #
  def show_values(topic = @topic, **opt)
    opt.reverse_merge!(name: topic)
    result = get_help_entry(topic)
    super(result, **opt)
  end

end

__loading_end(__FILE__)
