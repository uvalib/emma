# app/models/api/active_periodical.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Api::ActivePeriodical
#
# @attr [String]                 activeTitleId
# @attr [Array<AllowsType>]      allows
# @attr [String]                 assignedBy
# @attr [String]                 dateAdded
# @attr [Api::Format]            format
# @attr [String]                 lastUpdated
# @attr [Array<Api::Link>]       links
# @attr [Api::PeriodicalEdition] periodical
# @attr [Integer]                size
# @attr [Api::StatusModel]       status
#
# @see https://apidocs.bookshare.org/reference/index.html#_active_periodical
#
class Api::ActivePeriodical < Api::Record::Base

  include Api::Common::LinkMethods

  schema do
    attribute :activeTitleId, String
    has_many  :allows,        AllowsType
    attribute :assignedBy,    String
    attribute :dateAdded,     String
    has_one   :format,        Api::Format
    attribute :lastUpdated,   String
    has_many  :links,         Api::Link
    has_one   :periodical,    Api::PeriodicalEdition
    attribute :size,          Integer
    has_one   :status,        Api::StatusModel
  end

end

__loading_end(__FILE__)