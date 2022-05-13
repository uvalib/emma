# app/records/lookup/crossref/message/work.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Message schema for an item lookup.
#
# @attr [String] status               %w(ok)
# @attr [String] message_type         %w(work)
# @attr [String] message_version
# @attr [Work]   message
#
class Lookup::Crossref::Message::Work < Lookup::Crossref::Api::Message

  include Lookup::Crossref::Shared::CreatorMethods
  include Lookup::Crossref::Shared::DateMethods
  include Lookup::Crossref::Shared::IdentifierMethods
  include Lookup::Crossref::Shared::TitleMethods
  include Lookup::Crossref::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :message,         Lookup::Crossref::Record::Work
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
    Array.wrap(message)
  end

end

__loading_end(__FILE__)
