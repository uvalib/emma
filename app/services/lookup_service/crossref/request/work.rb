# app/services/lookup_service/crossref/request/work.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LookupService::Crossref::Request::Work
#
# @see https://api.crossref.org/swagger-ui/index.html#/Works
#
module LookupService::Crossref::Request::Work

  include LookupService::Crossref::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  # noinspection SpellCheckingInspection
  QUERY_PREFIX = {
    affiliation:              'affiliation',
    author:                   'author',
    bibliographic:            'bibliographic',
    chair:                    'chair',
    'container-title':        'container-title',
    container_title:          'container-title',
    journal_title:            'container-title',
    journal:                  'container-title',
    contributor:              'contributor',
    degree:                   'degree',
    description:              'description',
    abstract:                 'description',
    editor:                   'editor',
    'event-acronym':          'event-acronym',
    event_acronym:            'event-acronym',
    'event-location':         'event-location',
    event_location:           'event-location',
    'event-name':             'event-name',
    event_name:               'event-name',
    'event-sponsor':          'event-sponsor',
    event_sponsor:            'event-sponsor',
    'event-theme':            'event-theme',
    event_theme:              'event-theme',
    'funder-name':            'funder-name',
    funder_name:              'funder-name',
    funder:                   'funder-name',
    'publisher-location':     'publisher-location',
    publisher_location:       'publisher-location',
    'publisher-name':         'publisher-name',
    publisher_name:           'publisher-name',
    publisher:                'publisher-name',
    'standards-body-acronym': 'standards-body-acronym',
    standards_body_acronym:   'standards-body-acronym',
    'standards-body-name':    'standards-body-name',
    standards_body_name:      'standards-body-name',
    standards_body:           'standards-body-name',
    title:                    'title',
    translator:               'translator',
  }.freeze

  # @private
  QUERY_ALIAS = QUERY_PREFIX.keys.freeze

  # @private
  ID_TYPES = PublicationIdentifier.identifier_types

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET https://api.crossref.org/works/DOI
  #
  # @param [String] doi
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Lookup::Crossref::Message::Work]
  #
  # @see https://api.crossref.org/swagger-ui/index.html#operations-Works-get_works__doi_
  #
  def get_work(doi, **opt)
    # noinspection RubyMismatchedArgumentType
    opt = get_parameters(__method__, **opt)
    api(:get, 'works', doi, **opt)
    api_return(Lookup::Crossref::Message::Work)
  end
    .tap do |method|
      add_api method => {
        role: :anonymous, # Should succeed for any user.
      }
    end

  # == GET https://api.crossref.org/works?query=...
  #
  # @param [LookupService::Request, Array<String>, String] terms
  # @param [Hash]                                          opt
  #
  # @option opt [Array,Boolean,nil] :fields   Alias for :select
  #
  # @return [Lookup::Crossref::Message::WorkResults]
  #
  # @see https://api.crossref.org/swagger-ui/index.html#operations-Works-get_works
  #
  def get_work_list(terms, **opt)
    terms = query_terms!(terms, opt)
    ids = extract_hash!(terms, *ID_TYPES)
    opt[:filter] = [*opt[:filter], *ids.values] if ids.present?
    opt[:filter] &&= Array.wrap(opt[:filter]).compact.join(',')
    # noinspection RubyMismatchedArgumentType
    opt = get_parameters(__method__, **opt)
    api(:get, 'works', **terms, **opt)
    api_return(Lookup::Crossref::Message::WorkResults)
  end
    .tap do |method|
      add_api method => {
        alias: {
          q:      :query,
          fields: :select,
        },
        optional: {
          cursor: String,
          facet:  String,
          filter: String,
          mailto: String,
          offset: Integer,
          order:  String,
          query:  String,
          rows:   Integer,
          sample: Integer,
          select: String,
          sort:   String,
        },
        role:     :anonymous, # Should succeed for any user.
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
  # @return [Hash]
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
              if !value
                prefix
              elsif (prefix = QUERY_PREFIX[prefix.to_sym])
                "#{prefix}:#{value}"
              else
                value
              end
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
    result = {}
    terms.map! do |term|
      prefix, value = term.split(':', 2)
      if !value
        key   = :query
        value = prefix
      elsif ID_TYPES.include?(prefix.to_sym)
        key   = :"#{prefix}"
        value = term
      else
        key   = :"query.#{prefix}"
      end
      result[key] = [*result[key], value]
    end
    result
  end

end

__loading_end(__FILE__)
