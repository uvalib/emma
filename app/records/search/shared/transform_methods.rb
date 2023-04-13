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
    url = get_field_values(data, *field).first
    return unless url.blank?
    set_field_value!(data, field, generate_title_url)
  end

  # Set the original repository content download URL if not already present.
  #
  # @param [Hash, nil] data           Default: *self*.
  # @param [Symbol]    field
  #
  # @return [void]
  #
  def normalize_download_url!(data = nil, field: :emma_retrievalLink)
    url = get_field_values(data, *field).first
    return unless url.blank? || url.start_with?(BOOKSHARE_API_URL)
    set_field_value!(data, field, generate_download_url)
  end

end

__loading_end(__FILE__)
