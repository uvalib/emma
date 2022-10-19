# app/services/lookup_service/crossref/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LookupService::Crossref::Properties
#
module LookupService::Crossref::Properties

  include Emma::Constants

  include LookupService::RemoteService::Properties

  # ===========================================================================
  # :section: ApiService::Properties overrides
  # ===========================================================================

  public

  # E-mail address added to parameters to put the request in the "polite pool".
  #
  # @return [String, nil]
  #
  def api_user
    PROJECT_EMAIL || super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Crossref results can be limited by specifying a comma-separated list of
  # any of these elements via the 'select' URL parameter:
  #
  # @type [Array<String>]
  #
  SELECT_ELEMENTS = %w(
    DOI
    ISBN
    ISSN
    URL
    abstract
    accepted
    alternative-id
    approved
    archive
    article-number
    assertion
    author
    chair
    clinical-trial-number
    container-title
    content-created
    content-domain
    created
    degree
    deposited
    editor
    event
    funder
    group-title
    indexed
    is-referenced-by-count
    issn-type
    issue
    issued
    license
    link
    member
    original-title
    page
    posted
    prefix
    published
    published-online
    published-print
    publisher
    publisher-location
    reference
    references-count
    relation
    score
    short-container-title
    short-title
    standards-body
    subject
    subtitle
    title
    translator
    type
    update-policy
    update-to
    updated-by
    volume
  ).freeze

  # Attribute names which are expected as all uppercase.
  #
  # @type [Array<String>]
  #
  SELECT_ELEMENTS_UPCASE =
    SELECT_ELEMENTS.map { |v|
      v.downcase if v.match?(/[A-Z]/)
    }.compact.freeze

  # select_list
  #
  # @param [Array<Symbol>]
  #
  # @return [Array<String>]
  #
  # == Usage Notes
  # This might not be useful in general since #SELECT_ELEMENTS is missing a
  # few data items (e.g. 'edition-number', 'journal-issue', 'language').
  #
  def select_list(*attribute)
    attribute.map { |attr|
      v = attr.to_s
      v = SELECT_ELEMENTS_UPCASE.include?(v) ? v.upcase : v.dasherize
      next v if SELECT_ELEMENTS.include?(v)
      Log.warn { "#{self.class}.#{__method__}: #{attr} not included" }
    }.compact
  end

end

__loading_end(__FILE__)
