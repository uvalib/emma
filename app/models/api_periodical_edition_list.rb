# app/models/api_periodical_edition_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/link'
require 'api/status_model'
require 'api/periodical_edition'

# ApiPeriodicalEditionList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_periodical_edition_list
#
class ApiPeriodicalEditionList < Api::Message

  schema do
    has_many  :allows,             String
    attribute :limit,              Integer
    has_many  :links,              Link
    attribute :message,            StatusModel
    attribute :next,               String
    has_many  :periodicalEditions, PeriodicalEdition
    attribute :totalResults,       Integer
  end

end

__loading_end(__FILE__)
