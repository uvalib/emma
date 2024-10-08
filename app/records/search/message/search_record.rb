# app/records/search/message/search_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Metadata record schema for an EMMA Unified Search result.
#
# @see "en.emma.record.upload.emma_data"
#
# @see Search::Record::MetadataRecord       (duplicate schema)
# @see Search::Record::MetadataCommonRecord (schema subset)
#
class Search::Message::SearchRecord < Search::Api::Message

  include Search::Shared::CreatorMethods
  include Search::Shared::DateMethods
  include Search::Shared::IdentifierMethods
  include Search::Shared::LinkMethods
  include Search::Shared::TitleMethods
  include Search::Shared::TransformMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Search::Record::MetadataRecord

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @note The EMMA Unified Search API does not actually support returning a
  #   message of this form.
  #
  # @param [Faraday::Response, Model, Hash, String, nil] src
  # @param [Hash, nil]                                   opt
  #
  # @see SearchService::Action::Records#get_record
  #
  def initialize(src, opt = nil)
    opt = opt&.dup || {}
    rid = opt.delete(:record_id)
    rid = opt.delete(:recordId) || rid
    if src.is_a?(Faraday::Response)
      src = Search::Message::SearchRecordList.new(src)
    end
    if src.is_a?(Search::Message::SearchRecordList)
      src = src.records
      src = src.select { _1.emma_recordId == rid } if rid.present?
    end
    src = src.first if src.is_a?(Array)
    super
    normalize_data_fields!
  end

end

__loading_end(__FILE__)
