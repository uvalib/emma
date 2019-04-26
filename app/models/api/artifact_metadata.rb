# app/models/api/artifact_metadata.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'
require 'api/narrator'
require 'api/name'

# Api::ArtifactMetadata
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_artifact_metadata
#
class Api::ArtifactMetadata < Api::Record::Base

  schema do
    attribute :brailleCode,             String
    attribute :brailleGrade,            BrailleGrade2
    attribute :brailleMusicScoreLayout, BrailleMusicScoreLayout
    attribute :brailleType,             BrailleType
    attribute :dateAdded, IsoDate
    attribute :duration, IsoDuration
    attribute :externalIdentifierCode,  String
    attribute :format,                  String
    attribute :fundingSource,           String
    attribute :globalBookServiceId,     String
    attribute :narrator,                Narrator
    attribute :numberOfVolumes,         Integer
    attribute :producer,                String
    attribute :supplier,                String
    attribute :transcriber,             Name
  end

end

__loading_end(__FILE__)
