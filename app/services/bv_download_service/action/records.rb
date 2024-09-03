# app/services/bv_download_service/action/records.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods which support acquiring a record from the UVALIB-hosted AWS S3
# BiblioVault collections.
#
module BvDownloadService::Action::Records

  include BvDownloadService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the contents of an item from a BiblioVault collection.
  #
  # @param [String] item
  # @param [Hash]   opt               Passed to #aws_get_file.
  #
  # @return [String, nil]
  #
  def stream_item(item, **opt)
    parts = item.sub(%r{^[^/]+://}, '').split('/')
    if parts.first.downcase.include?('bibliovault')
      bucket = parts.shift.split('.').first
    else
      bucket = BV_BUCKET
    end
    key = parts.join('/')
    aws_get_file(bucket, key, **opt)
  end

end

__loading_end(__FILE__)
