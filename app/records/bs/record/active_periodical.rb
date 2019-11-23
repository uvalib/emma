# app/records/bs/record/active_periodical.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::ActivePeriodical
#
# @attr [String]                        activeTitleId
# @attr [Array<AllowsType>]             allows
# @attr [String]                        assignedBy
# @attr [IsoDate]                       dateAdded
# @attr [Bs::Record::Format]            format
# @attr [IsoDate]                       lastUpdated
# @attr [Array<Bs::Record::Link>]       links
# @attr [Bs::Record::PeriodicalEdition] periodical
# @attr [String]                        seriesId
# @attr [Integer]                       size
# @attr [Bs::Record::StatusModel]       status
# @attr [String]                        title
#
# @see https://apidocs.bookshare.org/reference/index.html#_active_periodical
#
class Bs::Record::ActivePeriodical < Bs::Api::Record

  include Bs::Shared::LinkMethods

  schema do
    attribute :activeTitleId, String
    has_many  :allows,        AllowsType
    attribute :assignedBy,    String
    attribute :dateAdded,     IsoDate
    has_one   :format,        Bs::Record::Format
    attribute :lastUpdated,   IsoDate
    has_many  :links,         Bs::Record::Link
    has_one   :periodical,    Bs::Record::PeriodicalEdition
    attribute :seriesId,      String
    attribute :size,          Integer
    has_one   :status,        Bs::Record::StatusModel
    attribute :title,         String
  end

end

__loading_end(__FILE__)
