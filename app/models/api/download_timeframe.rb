# app/models/api/download_timeframe.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

# Api::DownloadTimeframe
#
# @attr [Timeframe] name
#
# @see https://apidocs.bookshare.org/reference/index.html#_download_timeframe
#
class Api::DownloadTimeframe < Api::Record::Base

  schema do
    attribute :name, Timeframe
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
