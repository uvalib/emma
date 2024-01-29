# app/records/ingest/shared/transform_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting transformations of data fields.
#
module Ingest::Shared::TransformMethods

  include Api::Shared::TransformMethods
  include Ingest::Shared::CommonMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Because :dc_title is a required field for EMMA Unified Ingest, this value
  # is supplied if the metadata does not include a title.
  #
  # @type [String, nil]
  #
  MISSING_TITLE = config_text(:ingest, :missing_title).deep_freeze

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
    normalize_day_fields!(data)
    make_retrieval_link!(data)
    super(data)
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
  def make_retrieval_link!(data = nil)
    link, rid = get_field_values(data, *RETRIEVAL_FIELDS)
    return if link.present? || rid.blank?
    link = Upload.make_retrieval_link(rid)
    set_field_value!(data, :emma_retrievalLink, link)
  end

end

__loading_end(__FILE__)
