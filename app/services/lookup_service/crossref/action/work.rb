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
    terms = query_terms(terms, opt)
    ids   = extract_hash!(terms, *ID_TYPES)
    opt[:filter] = [*opt[:filter], *ids.values] if ids.present?
    opt[:filter] &&= Array.wrap(opt[:filter]).compact.join(',')
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

  # Options for LookupService::Request#add_term.
  # @private
  OPT = { author: QUERY_PREFIX.slice(*AUTHOR_TYPES).values }.deep_freeze

  # Aggregate terms into groups of similar search behavior.
  #
  # @param [LookupService::Request, Array<String>, String] terms
  # @param [Hash]                                          opt
  #
  # @return [Hash]
  #
  def query_terms(terms, opt)
    query = [*opt.delete(:q), *opt.delete(:query)].compact.presence
    other = extract_hash!(opt, *QUERY_ALIAS).presence
    if terms.is_a?(LookupService::Request)
      req = (query || other) ? terms.dup : terms
    else
      req = LookupService::Request.new
      Array.wrap(terms).each { |term| req.add_term(term, **OPT) }
    end
    query&.each { |term| req.add_term(term, **OPT) }
    other&.each { |prm, value| req.add_term(prm, value, **OPT) }
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
