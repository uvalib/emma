# app/records/bs/record/download_timeframe.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::DownloadTimeframe
#
# @attr [BsTimeframe] name
#
# @see https://apidocs.bookshare.org/membership/index.html#_download_timeframe
#
class Bs::Record::DownloadTimeframe < Bs::Api::Record

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :name, BsTimeframe
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Convert object to string.
  #
  # @return [String]
  #
  def to_s
    label
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A label for the item.
  #
  # @return [String]
  #
  def label
    name.to_s
  end

end

__loading_end(__FILE__)
