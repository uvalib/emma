# app/records/lookup/crossref/message/journal.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Message schema for a journal lookup.
#
# @attr [String]  status              %w(ok)
# @attr [String]  message_type        %w(journal)
# @attr [String]  message_version
# @attr [Journal] message
#
class Lookup::Crossref::Message::Journal < Lookup::Crossref::Api::Message

  include Lookup::Crossref::Shared::CreatorMethods
  include Lookup::Crossref::Shared::DateMethods
  include Lookup::Crossref::Shared::IdentifierMethods
  include Lookup::Crossref::Shared::TitleMethods
  include Lookup::Crossref::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :message,         Lookup::Crossref::Record::Journal
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
    Array.wrap(message)
  end

end

__loading_end(__FILE__)
