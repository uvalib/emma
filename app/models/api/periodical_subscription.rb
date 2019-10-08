# app/models/api/periodical_subscription.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Api::PeriodicalSubscription
#
# @attr [IsoDate]                              dateSubscribed
# @attr [PeriodicalFormatType]                 format
# @attr [Array<Api::Link>]                     links
# @attr [Api::PeriodicalSeriesMetadataSummary] periodical
#
# @see https://apidocs.bookshare.org/reference/index.html#_periodical_subscription
#
class Api::PeriodicalSubscription < Api::Record::Base

  include Api::Common::ArtifactMethods
  include Api::Common::LinkMethods

  schema do
    attribute :dateSubscribed, IsoDate
    attribute :format,         PeriodicalFormatType
    has_many  :links,          Api::Link
    has_one   :periodical,     Api::PeriodicalSeriesMetadataSummary
  end

end

__loading_end(__FILE__)
