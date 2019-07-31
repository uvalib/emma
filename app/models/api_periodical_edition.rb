# app/models/api_periodical_edition.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/periodical_edition'

# ApiPeriodicalEdition
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_periodical_edition
#
# NOTE: This duplicates:
# @see Api::PeriodicalEdition
#
class ApiPeriodicalEdition < Api::Message

  include Api::Common::ArtifactMethods
  include Api::Common::EditionMethods
  include Api::Common::LinkMethods

  schema do
    attribute :editionId,       String
    attribute :editionName,     String
    attribute :expirationDate,  String
    has_many  :formats,         Api::Format
    has_many  :links,           Api::Link
    attribute :publicationDate, String
  end

end

__loading_end(__FILE__)
