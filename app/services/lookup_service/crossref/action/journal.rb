# app/services/lookup_service/crossref/action/journal.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LookupService::Crossref::Action::Work
#
# @see https://api.crossref.org/swagger-ui/index.html#/Journals
#
module LookupService::Crossref::Action::Journal

  include Emma::Constants

  include LookupService::Crossref::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET https://api.crossref.org/journals/ISSN
  #
  # @param [String] issn
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Lookup::Crossref::Message::Journal]
  #
  # @see https://api.crossref.org/swagger-ui/index.html#operations-Journals-get_journals__issn_
  #
  def get_journal(issn, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'journals', issn, **opt)
    api_return(Lookup::Crossref::Message::Journal)
  end
    .tap do |method|
      add_api method => {
        role: :anonymous, # Should succeed for any user.
      }
    end

  # === GET https://api.crossref.org/journals?query=...
  #
  # @param [Hash] opt
  #
  # @return [Lookup::Crossref::Message::JournalResults]
  #
  # @see https://api.crossref.org/swagger-ui/index.html#operations-Journals-get_journals
  #
  def get_journal_list(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'journals', **opt)
    api_return(Lookup::Crossref::Message::JournalResults)
  end
    .tap do |method|
      add_api method => {
        alias: {
          q:        :query,
        },
        optional: {
          cursor:   String,
          #facet:   String,
          #filter:  String,
          mailto:   String,
          offset:   Integer,
          #order:   String,
          query:    String,
          rows:     Integer,
          #sample:  Integer,
          #select:  String,
          #sort:    String,
        },
        role:       :anonymous, # Should succeed for any user.
      }
    end

end

__loading_end(__FILE__)
