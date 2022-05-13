# app/records/lookup/google_books/shared/_common_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# General shared methods.
#
module Lookup::GoogleBooks::Shared::CommonMethods

  include Lookup::RemoteService::Shared::CommonMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  EXTENDED_FIELDS = true
  COMPLETE_FIELDS = false

  EXT = EXTENDED_FIELDS || COMPLETE_FIELDS
  ALL = COMPLETE_FIELDS

  # A traversal through the hierarchy rooted at the class instance which
  # holds all of the metadata for a single lookup result item.
  #
  # @type [Array<Symbol>]
  #
  ITEM_PATH = %i[volumeInfo].freeze

  # ===========================================================================
  # :section: Api::Shared::CommonMethods overrides
  # ===========================================================================

  protected

  # A traversal through the hierarchy rooted at the class instance which
  # holds all of the metadata for a single lookup result item.
  #
  # @return [Array<Symbol>]
  #
  def item_record_path
    ITEM_PATH
  end

  # Get the first non-empty value given a list of fields.
  #
  # @param [Array<Symbol>] fields
  # @param [Api::Record]   target     Default: `self`.
  #
  # @return [Array<String>]
  #
  def get_values(*fields, target: nil, **)
    # @type [Lookup::GoogleBooks::Record::VolumeInfo, nil]
    target = find_record_item(:volumeInfo, target: target) || target
    super(*fields, target: target)
  end

end

__loading_end(__FILE__)
