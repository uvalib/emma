# app/models/api/artifact_metadata.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

require_relative 'name'
require_relative 'narrator'

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
    attribute :dateAdded,               IsoDate
    attribute :duration,                IsoDuration
    attribute :externalIdentifierCode,  String
    attribute :format,                  String
    attribute :fundingSource,           String
    attribute :globalBookServiceId,     String
    has_one   :narrator,                Api::Narrator
    attribute :numberOfVolumes,         Integer
    attribute :producer,                String
    attribute :supplier,                String
    has_one   :transcriber,             Api::Name
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Convert object to string.
  #
  # @return [String]
  #
  def to_s
    label
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A label for the item.
  #
  # @return [String]
  #
  def label
    format.to_s
  end

  # A relative identiier for the represented artifact.
  #
  # @return [String]
  #
  def identifier
    format.to_s
  end

end

__loading_end(__FILE__)
