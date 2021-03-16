# app/records/bs/record/active_periodical.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::ActivePeriodical
#
# @attr [String]                        activeTitleId
# @attr [Array<BsAllowsType>]           allows
# @attr [String]                        assignedBy
# @attr [IsoDate]                       dateAdded
# @attr [Bs::Record::Format]            format
# @attr [Bs::Record::StatusModel]       downloadStatus
# @attr [Bs::Record::StatusModel]       fileResourceStatus
# @attr [IsoDate]                       lastUpdated
# @attr [Array<Bs::Record::Link>]       links
# @attr [Bs::Record::StatusModel]       packagingStatus     *deprecated*
# @attr [Bs::Record::PeriodicalEdition] periodical
# @attr [String]                        seriesId
# @attr [Integer]                       size
# @attr [Bs::Record::StatusModel]       status              *deprecated*
# @attr [String]                        title
#
# @see https://apidocs.bookshare.org/reference/index.html#_active_periodical
#
class Bs::Record::ActivePeriodical < Bs::Api::Record

  include Bs::Shared::LinkMethods

  schema do
    has_one   :activeTitleId
    has_many  :allows,              BsAllowsType
    has_one   :assignedBy
    has_one   :dateAdded,           IsoDate
    has_one   :downloadStatus,      Bs::Record::StatusModel
    has_one   :fileResourceStatus,  Bs::Record::StatusModel
    has_one   :format,              Bs::Record::Format
    has_one   :lastUpdated,         IsoDate
    has_many  :links,               Bs::Record::Link
    has_one   :packagingStatus,     Bs::Record::StatusModel # NOTE: deprecated
    has_one   :periodical,          Bs::Record::PeriodicalEdition
    has_one   :seriesId
    has_one   :size,                Integer
    has_one   :status,              Bs::Record::StatusModel # NOTE: deprecated
    has_one   :title
  end

end

__loading_end(__FILE__)
