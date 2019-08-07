# app/models/api_periodical_edition_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/common/link_methods'
require_relative 'api/periodical_edition'
require_relative 'api/status_model'

# ApiPeriodicalEditionList
#
# @attr [Array<AllowsType>]             allows
# @attr [Integer]                       limit
# @attr [Array<Api::Link>]              links
# @attr [Api::StatusModel]              message
# @attr [String]                        next
# @attr [Array<Api::PeriodicalEdition>] periodicalEditions
# @attr [Integer]                       totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_periodical_edition_list
#
class ApiPeriodicalEditionList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many  :allows,             AllowsType
    attribute :limit,              Integer
    has_many  :links,              Api::Link
    has_one   :message,            Api::StatusModel
    attribute :next,               String
    has_many  :periodicalEditions, Api::PeriodicalEdition
    attribute :totalResults,       Integer
  end

end

__loading_end(__FILE__)
