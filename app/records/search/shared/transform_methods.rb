# app/records/search/shared/transform_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting transformations of data fields.
#
module Search::Shared::TransformMethods

  include Api::Shared::TransformMethods
  include Search::Shared::CommonMethods
  include Search::Shared::LinkMethods

  extend self

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
  def normalize_data_fields!(data = self)
    normalize_download_url!(data)
    normalize_title_url!(data)
    super(data)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Set the URL of the associated work on the web site of the original
  # repository if not already present.
  #
  # @param [Hash, nil] data           Default: *self*.
  # @param [Symbol]    field
  #
  # @return [void]
  #
  def normalize_title_url!(data = nil, field: :emma_webPageLink)
    url = get_field_value(data, field)
    set_field_value!(data, field, generate_title_url) if url.blank?
  end

  # Set the original repository content download URL if not already present.
  #
  # For Internet Archive items, the value is replaced with one that will cause
  # a download request to proxy through EMMA.
  #
  # @param [Hash, nil] data           Default: *self*.
  # @param [Symbol]    field
  #
  # @return [void]
  #
  def normalize_download_url!(data = nil, field: :emma_retrievalLink)
    url = get_field_value(data, field)
    url = nil if url&.match?(%r{^https?://archive\.org/download/})
    set_field_value!(data, field, generate_download_url) if url.blank?
  end

end

__loading_end(__FILE__)
