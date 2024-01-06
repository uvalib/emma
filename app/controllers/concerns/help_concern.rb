# app/controllers/concerns/help_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/help" controller.
#
module HelpConcern

  extend ActiveSupport::Concern

  include HelpHelper

  include SerializationConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # get_help_entry
  #
  # @param [Symbol, nil] topic
  #
  # @return [Hash{Symbol=>*}]
  #
  def get_help_entry(topic)
    entry = HELP_ENTRY[topic]&.except(:content_html)
    if entry
      entry[:content] ||= 'TODO' # TODO: JSON/XML help content
    else
      entry = { error: 'Not a help topic.' }
    end
    entry
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Extract the URL parameter which specifies a help topic.
  #
  # @return [Symbol]                  Value of `params[:id]`.
  # @return [nil]                     No :id, :topic found.
  #
  def set_help_topic
    @topic = (params[:topic] || params[:id])&.to_sym
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
    topics = Array.wrap(list).map { |topic| show_values(topic) }
    topics = {}.merge!(*topics)
    super(topics, wrap: :help, **opt)
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Symbol] topic
  # @param [Hash]   opt
  #
  # @return [Hash{Symbol=>*}]
  #
  def show_values(topic = @topic, **opt)
    entry = get_help_entry(topic)
    super(entry, name: topic, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
