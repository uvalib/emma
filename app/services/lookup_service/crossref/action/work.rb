# app/services/lookup_service/crossref/action/work.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LookupService::Crossref::Action::Work
#
# @see https://api.crossref.org/swagger-ui/index.html#/Works
#
module LookupService::Crossref::Action::Work

  include LookupService::Crossref::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
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

  # @private
  AUTHOR_TYPES = %i[author contributor editor translator].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET https://api.crossref.org/works/DOI
  #
  # @param [String] doi
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Lookup::Crossref::Message::Work]
  #
  # @see https://api.crossref.org/swagger-ui/index.html#operations-Works-get_works__doi_
  #
  def get_work(doi, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'works', doi, **opt)
    api_return(Lookup::Crossref::Message::Work)
  end
    .tap do |method|
      add_api method => {
        role: :anonymous, # Should succeed for any user.
      }
    end

  # === GET https://api.crossref.org/works?query=...
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
    query = query_terms(terms, opt)
    ids   = query.extract!(*ID_TYPES)
    opt[:filter] = [*opt[:filter], *ids.values] if ids.present?
    opt[:filter] &&= Array.wrap(opt[:filter]).compact.join(',')
    opt = get_parameters(__method__, **opt)
    api(:get, 'works', **query, **opt)
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

  # Options for LookupService::Request#add_term.
  #
  # @type [Hash{Symbol=>any}]
  #
  # @private
  #
  OPT = { author: QUERY_PREFIX.slice(*AUTHOR_TYPES).values }.deep_freeze

  # Aggregate terms into groups of similar search behavior.
  #
  # All query-related keys are removed from *opt*.
  #
  # @param [LookupService::Request, Array<String>, String] terms
  # @param [Hash]                                          opt
  #
  # @return [Hash]
  #
  def query_terms(terms, opt)
    opt   = opt.compact_blank
    query = opt.extract!(:q, :query).presence&.values&.first
    other = opt.extract!(*QUERY_ALIAS).presence
    if terms.is_a?(LookupService::Request)
      req = (query || other) ? terms.dup : terms
    else
      req = LookupService::Request.new
      Array.wrap(terms).each { req.add_term(_1, **OPT) }
    end
    query&.each { req.add_term(_1, **OPT) }
    other&.each { req.add_term(_1, _2, **OPT) }
    result = {}
    req.terms.each do |term|
      prefix, value = term.split(':', 2)
      next if prefix.blank?
      if value.blank?
        prefix, value = [nil, prefix]
      elsif !ID_TYPES.include?((prefix = prefix.to_sym))
        prefix = QUERY_PREFIX[prefix] || prefix
        prefix = "query.#{prefix}"
      end
      key = prefix || :query
      result[key] = [*result[key], value]
    end
    result
  end

end

__loading_end(__FILE__)
