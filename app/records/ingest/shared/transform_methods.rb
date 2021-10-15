# app/records/ingest/shared/transform_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting transformations of data fields.
#
module Ingest::Shared::TransformMethods

  include Api::Shared::TransformMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Because :dc_title is a required field for ingest into Unified Search, this
  # value is supplied if the metadata does not include a title.
  #
  # @type [String, nil] # TODO: MISSING_TITLE: I18n - keep?
  #
  MISSING_TITLE = '[TITLE MISSING]'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform data fields.
  #
  # @param [Hash, nil] data           Default: *self*.
  #
  # @return [void]
  #
  def normalize_data_fields!(data = nil)

    # === Standard Identifiers ===
    normalize_identifier_fields!(data)
    clean_dc_relation!(data)

    # === Dates ===
    normalize_day_fields!(data)
    normalize_title_dates!(data)

    # === Required fields ===
    make_retrieval_link!(data)

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # @private
  RETRIEVAL_FIELDS = %i[emma_retrievalLink emma_repositoryRecordId].freeze

  # Produce a retrieval link for an item.
  #
  # @param [Hash, nil] data           Default: *self*.
  #
  # @return [void]
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def make_retrieval_link!(data = nil)
    link, rid = get_field_values(data, RETRIEVAL_FIELDS)
    return if link.present? || rid.blank?
    link = Upload.make_retrieval_link(rid)
    if data
      data[:emma_retrievalLink] = link
    else
      try('emma_retrievalLink=', link)
    end
  end

end

__loading_end(__FILE__)
