# app/controllers/concerns/home_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for "/home" pages.
#
module HomeConcern

  extend ActiveSupport::Concern

  include SerializationConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Bookshare account details (defunct).
  #
  attr_reader :details

  # Bookshare account preferences (defunct).
  #
  attr_reader :preferences

  # Bookshare download history (defunct).
  #
  attr_reader :history

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  public

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Hash, nil] entry
  # @param [Hash]      opt
  #
  # @return [Hash{Symbol=>Hash,Array}]
  #
  def show_values(entry = nil, **opt)
    entry ||= { details: details, preferences: preferences, history: history }
    opt.reverse_merge!(name: :account)
    super
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
