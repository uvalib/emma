# app/records/bs/record/periodical_subscription.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::PeriodicalSubscription
#
# @attr [IsoDate]                                     dateSubscribed
# @attr [BsPeriodicalFormat]                          format
# @attr [Array<Bs::Record::Link>]                     links
# @attr [Bs::Record::PeriodicalSeriesMetadataSummary] periodical
#
# @see https://apidocs.bookshare.org/reference/index.html#_periodical_subscription
#
class Bs::Record::PeriodicalSubscription < Bs::Api::Record

  include Bs::Shared::ArtifactMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :dateSubscribed, IsoDate
    has_one   :format,         BsPeriodicalFormat
    has_many  :links,          Bs::Record::Link
    has_one   :periodical,     Bs::Record::PeriodicalSeriesMetadataSummary
  end

end

__loading_end(__FILE__)
