# app/records/bs/message/periodical_series_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::PeriodicalSeriesMetadataSummary
#
# @see Bs::Record::PeriodicalSeriesMetadataSummary
#
class Bs::Message::PeriodicalSeriesMetadataSummary < Bs::Api::Message

  include Bs::Shared::LinkMethods
  include Bs::Shared::PeriodicalMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Bs::Record::PeriodicalSeriesMetadataSummary

end

__loading_end(__FILE__)
