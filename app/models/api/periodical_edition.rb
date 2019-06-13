# app/models/api/periodical_edition.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

require_relative 'format'
require_relative 'link'
require_relative 'common/edition_methods'

# Api::PeriodicalEdition
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_periodical_edition
#
# NOTE: This duplicates:
# @see ApiPeriodicalEdition
#
class Api::PeriodicalEdition < Api::Record::Base

  schema do
    attribute :editionId,       String
    attribute :editionName,     String
    attribute :expirationDate,  String
    has_many  :formats,         Api::Format
    has_many  :links,           Api::Link
    attribute :publicationDate, String
  end

  include Api::Common::EditionMethods

end

__loading_end(__FILE__)
