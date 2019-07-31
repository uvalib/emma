# app/models/api/periodical_edition.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'common/artifact_methods'
require_relative 'common/edition_methods'
require_relative 'common/link_methods'

# Api::PeriodicalEdition
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_periodical_edition
#
# NOTE: This duplicates:
# @see ApiPeriodicalEdition
#
class Api::PeriodicalEdition < Api::Record::Base

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
