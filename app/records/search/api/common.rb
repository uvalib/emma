# app/records/search/api/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/common'

# Shared values and methods.
#
# @see Api::Common
#
module Search::Api::Common

  include ::Api::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Values associated with each source repository.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  REPOSITORY =
    I18n.t('emma.source').reject { |k, _| k.to_s.start_with?('_') }.deep_freeze

  # Enumeration scalar type names and properties.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  ENUMERATIONS = {

    EmmaRepository: {
      values: %w(
        emma
        bookshare
        hathiTrust
        internetArchive
      )
    },

    FormatFeature: {
      values: %w(
        tts
        human
        grade1
        grade2
        nemeth
        technical
        ueb
        ebae
        literary
        music
      )
    },

    Rights: {
      values: %w(
        publicDomain
        creativeCommons
        copyright
      )
    },

    Provenance: {
      values: %w(
        publisher
        volunteer
      )
    },

    DublinCoreFormat: {
      values: %w(
        brf
        daisy
        daisyAudio
        epub
        braille
        pdf
        word
        tactile
        kurzweil
        rtf
      )
    },

    DcmiType: {
      values: %w(
        text
        sound
        collection
        dataset
        event
        image
        interactiveResource
        service
        physicalObject
        stillImage
        movingImage
      )
    },

    A11yFeature: {
      values: %w(
        alternativeText
        annotations
        audioDescription
        bookmarks
        braille
        captions
        ChemML
        describedMath
        displayTransformability
        displayTransformability/background-color
        displayTransformability/color
        displayTransformability/font-height
        displayTransformability/font-size
        displayTransformability/line-height
        displayTransformability/word-spacing
        highContrastAudio
        highContrastDisplay
        index
        largePrint
        latex
        longDescription
        MathML
        physicalObject
        printPageNumbers
        readingOrder
        rubyAnnotations
        signLanguage
        sound
        stillImage
        structuralNavigation
        synchronizedAudioText
        tactileGraphic
        tactileObject
        taggedPDF
        timingControl
        transcript
        ttsMarkup
        unlocked
      )
    },

    A11yControl: {
      values: %w(
        fullAudioControl
        fullKeyboardControl
        fullMouseControl
        fullTouchControl
        fullVideoControl
        fullSwitchControl
        fullVoiceControl
      )
    },

    A11yHazard: {
      values: %w(
        flashing
        noFlashingHazard
        motionSimulation
        noMotionSimulationHazard
        sound
        noSoundHazard
      )
    },

    A11yAPI: {
      values: %w(ARIA),
    },

    A11yAccessMode: {
      values: %w(
        auditory
        chartOnVisual
        chemOnVisual
        colorDependent
        diagramOnVisual
        mathOnVisual
        musicOnVisual
        tactile
        textOnVisual
        textual
        visual
      )
    },

    A11ySufficient: {
      values: %w(
        auditory
        tactile
        textual
        visual
      )
    },

    SearchSort: {
      values: %w(
        title
        lastRemediationDate
      )
    }

  }.deep_freeze.tap { |entries| ::EnumType.add_enumerations(entries) }

end

# =============================================================================
# Definitions of new fundamental "types"
# =============================================================================

public

# PublicationIdentifier
#
# ISBN-10   10
# ISBN-13   13
# ISSN      8
# UPC       12
# OCN       >= 8
#
class PublicationIdentifier < ScalarType

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  def valid?(v = nil)
    v = v&.to_s&.strip || @value
    v.match?(/^(isbn|oclc|upc|issn):[0-9X]{8,14}$/i)
  end

end

# =============================================================================
# Generate top-level classes associated with each enumeration entry so that
# they can be referenced without prepending a namespace.
# =============================================================================

class EmmaRepository   < EnumType; end
class FormatFeature    < EnumType; end
class Rights           < EnumType; end
class Provenance       < EnumType; end
class DublinCoreFormat < EnumType; end
class DcmiType         < EnumType; end
class A11yFeature      < EnumType; end
class A11yControl      < EnumType; end
class A11yHazard       < EnumType; end
class A11yAPI          < EnumType; end
class A11yAccessMode   < EnumType; end
class A11ySufficient   < EnumType; end
class SearchSort       < EnumType; end

__loading_end(__FILE__)
