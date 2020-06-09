# app/records/bs/message/periodical_edition.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::PeriodicalEdition
#
# @attr [String]                    editionId
# @attr [String]                    editionName
# @attr [IsoDate]                   expirationDate
# @attr [Array<Bs::Record::Format>] formats
# @attr [Array<Bs::Record::Link>]   links
# @attr [IsoDate]                   publicationDate
#
# @see https://apidocs.bookshare.org/reference/index.html#_periodical_edition
#
# NOTE: This duplicates:
# @see Bs::Record::PeriodicalEdition
#
#--
# noinspection DuplicatedCode
#++
class Bs::Message::PeriodicalEdition < Bs::Api::Message

  include Bs::Shared::ArtifactMethods
  include Bs::Shared::EditionMethods
  include Bs::Shared::LinkMethods

  schema do
    attribute :editionId,       String
    attribute :editionName,     String
    attribute :expirationDate,  IsoDate
    has_many  :formats,         Bs::Record::Format
    has_many  :links,           Bs::Record::Link
    attribute :publicationDate, IsoDate
  end

end

__loading_end(__FILE__)
