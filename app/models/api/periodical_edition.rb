# app/models/api/periodical_edition.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'
require 'api/format'
require 'api/link'

# Api::PeriodicalEdition
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_periodical_edition
#
class Api::PeriodicalEdition < Api::Record::Base

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
