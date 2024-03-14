# app/services/lookup_service/world_cat/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LookupService::WorldCat::Properties
#
module LookupService::WorldCat::Properties
  include LookupService::RemoteService::Properties
end

# noinspection SpellCheckingInspection
unless ONLY_FOR_DOCUMENTATION
# :nocov:
=begin # NOTE: preserved for possible future use
# LookupService::WorldCatV2::Properties
#
module LookupService::WorldCatV2::Properties

  include LookupService::RemoteService::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Array<String>]
  # noinspection SpellCheckingInspection
  ITEM_TYPE = %w[
    Archv
    ArtChapter
    AudioBook
    Book
    CompFile
    Encyc
    Game
    Image
    IntMM
    Jrnl
    Kit
    Map
    MsScr
    Music
    News
    Object
    Snd
    Toy
    Video
    Vis
    Web
  ].freeze

  # @type [Array<String>]
  SEARCH_ITEM_TYPE = ITEM_TYPE.map(&:downcase).deep_freeze

  # @type [Array<String>]
  # noinspection SpellCheckingInspection
  ITEM_SUBTYPE = %w(
    archv-digital
    archv-
    artchap-artcl
    artchap-chptr
    artchap-digital
    artchap-mss
    audiobook-cd
    audiobook-cassette
    audiobook-digital
    audiobook-lp
    audiobook-
    book-printbook
    book-digital
    book-mic
    book-thsis
    book-mss
    book-largeprint
    book-braille
    book-continuing
    book-
    compfile-digital
    compfile-
    encyc-
    game-digital
    game-
    image-2d
    intmm-digital
    intmm-
    jrnl-print
    jrnl-digital
    kit-
    map-
    map-mss
    map-digital
    msscr-digital
    msscr-mss
    msscr-
    music-cd
    music-lp
    music-digital
    music-cassette
    music-
    news-digital
    news-print
    object-digital
    object-
    snd-
    snd-rec
    toy-
    video-dvd
    video-vhs
    video-digital
    video-film
    video-bluray
    video-
    vis-digital
    vis-
    web-digital
    web-dwn2d
    web-
  ).freeze

  # @type [Array<String>]
  # noinspection SpellCheckingInspection
  FORMAT_TYPE = %w[
    2D
    Artcl
    Bluray
    Braille
    Cassette
    CD
    Chptr
    Continuing
    Digital
    DVD
    Encyc
    Film
    LargePrint
    LP
    Mic
    mss
    PrintBook
    rec
    Thsis
    VHS
  ].freeze

  # @type [Array<String>]
  # noinspection SpellCheckingInspection
  FACET = %w(
    subject
    creator
    datePublished
    genre
    itemType
    itemSubTypeBrief
    itemSubType
    language
    topic
    subtopic
    content
    audience
    databases
  ).freeze

  # @type [Array<String>]
  # noinspection SpellCheckingInspection
  SORT_ORDER = %w[
    bestMatch
    library
    recency
    creator
    publicationDateAsc
    publicationDateDesc
    mostWidelyHeld
    title
  ].freeze

  # @type [Array<String>]
  # noinspection SpellCheckingInspection
  SUBJECT_TYPES = [
    "LC subject headings for children's literature",
    'Library of Congress Subject Headings',
    'bisacsh',
    'cct',
    'fast',
    'gsafd',
    'lcgft',
    'sears', # ...
  ].freeze

  # @type [Array<String>]
  # noinspection SpellCheckingInspection
  RELATIONSHIP_TYPES = [
    'unknown',
    'resource',
    'version of resource',
    'related resource',
  ].freeze

end
=end
# :nocov:
end

__loading_end(__FILE__)
