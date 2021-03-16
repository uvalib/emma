# app/records/bs/record/artifact_metadata.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::ArtifactMetadata
#
# @attr [String]                    brailleCode
# @attr [BsBrailleGrade]            brailleGrade
# @attr [BsBrailleMusicScoreLayout] brailleMusicScoreLayout
# @attr [BsBrailleType]             brailleType
# @attr [IsoDate]                   dateAdded
# @attr [IsoDuration]               duration
# @attr [String]                    externalIdentifierCode
# @attr [String]                    format
# @attr [String]                    fundingSource
# @attr [String]                    globalBookServiceId
# @attr [Bs::Record::Narrator]      narrator
# @attr [Integer]                   numberOfVolumes
# @attr [String]                    producer
# @attr [String]                    supplier
# @attr [Bs::Record::Name]          transcriber
#
# @see https://apidocs.bookshare.org/reference/index.html#_artifact_metadata
#
class Bs::Record::ArtifactMetadata < Bs::Api::Record

  include Bs::Shared::ArtifactMethods

  schema do
    has_one   :brailleCode
    has_one   :brailleGrade,            BsBrailleGrade
    has_one   :brailleMusicScoreLayout, BsBrailleMusicScoreLayout
    has_one   :brailleType,             BsBrailleType
    has_one   :dateAdded,               IsoDate
    has_one   :duration,                IsoDuration
    has_one   :externalIdentifierCode
    has_one   :format
    has_one   :fundingSource
    has_one   :globalBookServiceId
    has_one   :narrator,                Bs::Record::Narrator
    has_one   :numberOfVolumes,         Integer
    has_one   :producer
    has_one   :supplier
    has_one   :transcriber,             Bs::Record::Name
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
    fmt
  end

  # A relative identifier for the represented artifact.
  #
  # @return [String]
  #
  def identifier
    fmt
  end

end

__loading_end(__FILE__)
