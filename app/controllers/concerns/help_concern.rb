# app/controllers/concerns/help_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# HelpConcern
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
  # @return [Hash]
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

end

__loading_end(__FILE__)
