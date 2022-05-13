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
  def get_volumes(terms, **opt)
    $stderr.puts
    $stderr.puts ">>> get_volumes | terms = #{terms.inspect}"
    terms = query_terms!(terms, opt)
    lccns = terms.select { |v| v.start_with?('lccn:') }.presence
    ids   = terms.map { |t| t.split(':', 2).first }.intersect?(ID_TYPES)
    opt[:foreign] = false unless ids
    opt[:q] = terms.join(' ')

    # noinspection RubyMismatchedArgumentType
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

  # query_terms!
  #
  # @param [LookupService::Request, Array<String>, String] terms
  # @param [Hash]                                          opt
  #
  # @return [Array<String>]
  #
  def query_terms!(terms, opt)
    if terms.is_a?(LookupService::Request)
      terms =
        terms.request.map do |k, items|
          if k == :ids
            terms.identifiers
          elsif items.present?
            items.map do |item|
              prefix, value = item.split(':', 2)
              if prefix && value
                prefix = QUERY_PREFIX[prefix.to_sym]
              else
                prefix, value = [nil, prefix]
              end
              [prefix, value].compact.join(':')
            end
          end
        end
    end
    terms = [*terms, *opt.delete(:q), *opt.delete(:query)]
    terms.flatten!
    terms.map! { |term| term.to_s.strip }
    terms +=
      (QUERY_ALIAS & opt.keys).flat_map do |prm|
        prefix = QUERY_PREFIX[prm]
        Array.wrap(opt.delete(prm)).map(&:to_s).map! { |v| "#{prefix}:#{v}" }
      end
    terms.compact_blank!
  end

end

__loading_end(__FILE__)
