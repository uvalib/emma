# app/models/api_periodical_edition.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/periodical_edition'

# ApiPeriodicalEdition
#
# NOTE: This duplicates Api::PeriodicalEdition
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_periodical_edition
#
class ApiPeriodicalEdition < Api::Message

  schema do
    attribute :editionId,       String
    attribute :editionName,     String
    attribute :expirationDate,  String
    has_many  :formats,         Format
    has_many  :links,           Link
    attribute :publicationDate, String
  end

end

__loading_end(__FILE__)
