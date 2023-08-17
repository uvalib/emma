# app/records/lookup/crossref/message/work_results.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Message schema for search by DOI.
#
# @attr [String] status               %w[ok]
# @attr [String] message_type         %w[work-list]
# @attr [String] message_version
# @attr [Work]   message
#
class Lookup::Crossref::Message::WorkResults < Lookup::Crossref::Api::Message

  include Lookup::Crossref::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :message,         Lookup::Crossref::Record::ListWorks
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
  # @return [Array<Lookup::Crossref::Record::Work>]
  #
  def api_records
    Array.wrap(message&.items)
  end

end

__loading_end(__FILE__)
