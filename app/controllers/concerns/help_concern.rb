# app/controllers/concerns/help_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/help" controller.
#
module HelpConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'HelpConcern')
  end

  include HelpHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # get_help_entry
  #
  # @param [Symbol] topic
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

end

__loading_end(__FILE__)
