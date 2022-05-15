# app/services/lookup_service/google_books/request/volumes.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LookupService::GoogleBooks::Request::Volumes
#
module LookupService::GoogleBooks::Request::Volumes

  include LookupService::GoogleBooks::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  # noinspection SpellCheckingInspection
  QUERY_PREFIX = {
    author:     'inauthor',    # Look for text in the authors.
    isbn:       'isbn',
    lccn:       'lccn',
    oclc:       'oclc',
    publisher:  'inpublisher', # Look for text in the publisher.
    subject:    'subject',     # Look in the category list of the volume.
    title:      'intitle',     # Look for text in the title.
  }.freeze

  # @private
  QUERY_ALIAS = QUERY_PREFIX.keys.freeze

  # @private
  ID_TYPES = PublicationIdentifier.identifier_types.map(&:to_s).deep_freeze

  # @private
  AUTHOR_TYPES = %i[author].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET https://www.googleapis.com/books/v1/volumes
  #
  # The service will match "lccn" numbers, but it won't include them in the
  # list of identifiers for the result.  For that reason, the returned object
  # is modified in-place to include searched-for LCCN items.
  #
  # @param [LookupService::Request, Array<String>, String] terms
  # @param [Hash]                                          opt
  #
  # @option opt [Boolean] :compact  Passed to #get_parameters
  # @option opt [Boolean] :foreign  Passed to #get_parameters
  #
  # @return [Lookup::GoogleBooks::Message::List]
  #
  # @see https://developers.google.com/books/docs/v1/reference/volumes/list
  # @see https://developers.google.com/books/docs/v1/using#PerformingSearch
  # @see https://developers.google.com/books/docs/v1/using#api_params
  # @see https://cloud.google.com/apis/docs/system-parameters
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def get_volumes(terms, **opt)
    terms = query_terms!(terms, opt)
    lccns = terms.select { |v| v.start_with?('lccn:') }.presence
    ids   = terms.map { |v| v.split(':', 2).first }.intersect?(ID_TYPES)
    opt[:foreign] = false unless ids
    opt[:q] = make_query(terms)

    opt = get_parameters(__method__, **opt)

    api(:get, 'volumes', **opt)
    api_return(Lookup::GoogleBooks::Message::List).tap do |result|
      if lccns
        # @type [Lookup::GoogleBooks::Record::Item] item
        result.items.each do |item|
          ids = item&.volumeInfo&.industryIdentifiers&.map(&:to_s) || []
          next if lccns.include?(ids.first.to_s)
          missing = lccns - ids
          # noinspection RubyMismatchedReturnType
          missing.map! { |id| Lookup::GoogleBooks::Record::Identifier.new(id) }
          item.volumeInfo.industryIdentifiers.insert(0, *missing)
        end
      end
    end
  end
    .tap do |method|
      add_api method => {
        alias: {
          language:                 :langRestrict,
          sort:                     :orderBy,
        },
        required: {
          q:                        String,
        },
        optional: {
          download:                 String,   # %w(epub)
          filter:                   String,   # %w(ebooks free-ebooks full paid-ebooks partial)
          langRestrict:             String,
          libraryRestrict:          String,   # %w(my-library no-restrict)
          maxAllowedMaturityRating: String,   # %w(mature not-mature)
          maxResults:               Integer,  # 0..40
          orderBy:                  String,   # %w(newest relevance)
          partner:                  String,
          printType:                String,   # %w(all books magazines)
          projection:               String,   # %w(full lite)
          showPreorders:            Boolean,
          source:                   String,
          startIndex:               Integer,
          volumeId:                 String,
        },
        role:  :anonymous, # Should succeed for any user.
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Options for LookupService::Request#add_term.
  # @private
  OPT = { author: QUERY_PREFIX.slice(*AUTHOR_TYPES).values }.deep_freeze

  # query_terms!
  #
  # @param [LookupService::Request, Array<String>, String] terms
  # @param [Hash]                                          opt
  #
  # @return [Array<String>]
  #
  def query_terms!(terms, opt)
    query = [*opt.delete(:q), *opt.delete(:query)].compact.presence
    other = extract_hash!(opt, *QUERY_ALIAS).presence
    if terms.is_a?(LookupService::Request)
      req = (query || other) ? terms.dup : terms
    else
      req = LookupService::Request.new
      Array.wrap(terms).each { |term| req.add_term(term, **OPT) }
    end
    query&.each { |term| req.add_term(term, **OPT) }
    other&.each { |prm, value| req.add_term(QUERY_PREFIX[prm], value, **OPT) }
    req.terms
  end

  # Combine terms to make a Google Books query string.
  #
  # @param [Array<String>] terms
  #
  # @return [String]
  #
  def make_query(terms)
    terms.join(' ')
  end

end

__loading_end(__FILE__)
