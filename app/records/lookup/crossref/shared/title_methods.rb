# app/records/lookup/crossref/shared/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to catalog titles.
#
module Lookup::Crossref::Shared::TitleMethods

  include Lookup::RemoteService::Shared::TitleMethods
  include Lookup::Crossref::Shared::DateMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Types of works identified by Crossref.
  #
  # @type [Hash{String=>String}]
  #
  # @see https://api.crossref.org/types
  #
  CROSSREF_ITEM_TYPE = {
    'book':                 'Book',
    'book-chapter':         'Book Chapter',
    'book-part':            'Part',
    'book-section':         'Book Section',
    'book-series':          'Book Series',
    'book-set':             'Book Set',
    'book-track':           'Book Track',
    'component':            'Component',
    'dataset':              'Dataset',
    'dissertation':         'Dissertation',
    'edited-book':          'Edited Book',
    'grant':                'Grant',
    'journal':              'Journal',
    'journal-article':      'Journal Article',
    'journal-issue':        'Journal Issue',
    'journal-volume':       'Journal Volume',
    'monograph':            'Monograph',
    'other':                'Other',
    'peer-review':          'Peer Review',
    'posted-content':       'Posted Content',
    'proceedings':          'Proceedings',
    'proceedings-article':  'Proceedings Article',
    'proceedings-series':   'Proceedings Series',
    'reference-book':       'Reference Book',
    'reference-entry':      'Reference Entry',
    'report':               'Report',
    'report-series':        'Report Series',
    'standard':             'Standard',
    'standard-series':      'Standard Series',
  }.stringify_keys.deep_freeze

  # ===========================================================================
  # :section: Api::Shared::TitleMethods overrides
  # ===========================================================================

  public

  # Field(s) that may hold the title string.
  #
  # @return [Array<Symbol>]
  #
  def title_fields
    %i[title]
  end

  # Field(s) that may hold the subtitle string.
  #
  # @return [Array<Symbol>]
  #
  def subtitle_fields
    %i[subtitle]
  end

  # Field(s) that may hold the name of the container/aggregate for an article.
  #
  # @return [Array<Symbol>]
  #
  def journal_title_fields
    %i[container_title]
  end

  # ===========================================================================
  # :section: Api::Shared::TitleMethods overrides
  # ===========================================================================

  public

  # One or more title strings.
  #
  # @return [Array<String>]
  #
  def title_values
    find_record_values(:title)
  end

  # One or more subtitle strings.
  #
  # @return [Array<String>]
  #
  def subtitle_values
    find_record_values(:subtitle)
  end

  # ===========================================================================
  # :section: Lookup::RemoteService::Shared::TitleMethods overrides
  # ===========================================================================

  public

  # Map Crossref work type on to a SeriesType value.
  #
  # @return [String]
  #
  # @see #CROSSREF_ITEM_TYPE
  # @see 'en.emma.search.type.SeriesType'
  #
  def series_type
    type = super(:type).to_s.downcase
    type.start_with?('journal', 'proceedings') ? 'Journal' : 'Book'
  end

  # The volume of the journal containing an article (if relevant).
  #
  # @return [String, nil]
  #
  def series_volume
    super(:volume)
  end

  # The issue of the journal containing an article (if relevant).
  #
  # @return [String, nil]
  #
  def series_issue
    super(:issue)
  end

  # ===========================================================================
  # :section: Lookup::RemoteService::Shared::TitleMethods overrides
  # ===========================================================================

  public

  # Name of publisher.
  #
  # @return [String, nil]
  #
  def publisher_name
    super(:publisher)
  end

  # The place of publication.
  #
  # @return [String, nil]
  #
  def publication_place
    super(:publisher_location)
  end

  # The date of publication.
  #
  # @return [String, nil]
  #
  def publication_date
    to_date&.strftime('%F')
  end

  # The year of publication.
  #
  # @return [String, nil]
  #
  def publication_year
    to_date&.strftime('%Y')
  end

end

__loading_end(__FILE__)
