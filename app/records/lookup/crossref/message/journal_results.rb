# app/records/lookup/crossref/message/journal_results.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Message schema for search by DOI.
#
# @attr [String] status               %w[ok]
# @attr [String] message_type         %w[work]
# @attr [String] message_version
# @attr [Work]   message
#
#--
# noinspection LongLine
#++
class Lookup::Crossref::Message::JournalResults < Lookup::Crossref::Api::Message

  include Lookup::Crossref::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :message,         Lookup::Crossref::Record::ListJournals
    has_one :message_type
    has_one :message_version
    has_one :status
  end

  # ===========================================================================
  # :section: Lookup::RemoteService::Shared::ResponseMethods overrides
  # ===========================================================================

  public

  # api_records
  #
  # @return [Array<Lookup::Crossref::Record::Journal>]
  #
  def api_records
    Array.wrap(message&.items)
  end

end

__loading_end(__FILE__)
