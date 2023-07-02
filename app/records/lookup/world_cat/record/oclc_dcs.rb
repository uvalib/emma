# app/records/lookup/world_cat/record/oclc_dcs.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Partial record schema for WorldCat API results.
#
# @attr [Array<String>] dc_creator
# @attr [Array<String>] dc_contributor                # NOTE: Fields [1]
# @attr [Array<String>] dc_date
# @attr [Array<String>] dc_description
# @attr [Array<String>] dc_format                     # NOTE: Fields [2]
# @attr [Array<String>] dc_identifier                 # NOTE: Fields [3]
# @attr [Array<String>] dc_language                   # NOTE: Fields [4]
# @attr [Array<String>] dc_publisher
# @attr [Array<String>] dc_relation
# @attr [Array<String>] dc_rights
# @attr [Array<String>] dc_subject                    # NOTE: Fields [5]
# @attr [Array<String>] dc_title
# @attr [String]        dc_type
# @attr [Array<String>] oclcterms_recordContentSource
# @attr [String]        oclcterms_recordCreationDate
# @attr [String]        oclcterms_recordIdentifier    # NOTE: Fields [6]
#
# === Fields
# - [1] :dc_contributor
#   * Role is not included, so these *could* be second authors, but they could
#     also be editors, translators, forward-by, etc.
# - [2] :dc_format
#   * Generally a narrative description of the physical item; e.g.:
#       "xvi, 709 pages : illustrations, portraits ; 23 cm."
# - [3] :dc_identifier
#   * No attribute:
#       ISBN-13 or ISBN-10 (value only; no "isbn:" prefix) *-OR-*
#       DOI (value only; no "doi:" prefix)
#   * xsi:type="http://purl.org/dc/terms/URI"
#       Online location of the item or a search yielding the item *-OR-*
#       A full DOI beginning with "https://doi.org/"
# - [4] :dc_language
#   * No attribute:
#       May be a narrative description; e.g.: "In English."
#   * xsi:type="http://purl.org/dc/terms/ISO639-2"
#       Three-letter language code.
# - [5] :dc_subject
#   * No attribute:
#       May be the same as LCSH...
#   * xsi:type="http://purl.org/dc/terms/LCSH"
#       Library of Congress Subject Heading
#   * xsi:type="http://purl.org/dc/terms/LCC"
#       Library of Congress call number - should probably be ignored.
#   * xsi:type="http://purl.org/dc/terms/DDC"
#       Unidentified - should probably be ignored.
# - [6] :oclcterms_recordIdentifier
#   * No attribute:
#       The OCLC number (value only; no "oclc:", "ocm", "ocn", etc. prefix)
#   * xsi:type="http://purl.org/oclc/terms/lccn"
#       The LCCN (value only; NOTE: including leading and trailing spaces)
#
# @see https://developer.api.oclc.org/wcv1#operations-SRU-search-sru
#
#--
# noinspection LongLine
#++
class Lookup::WorldCat::Record::OclcDcs < Lookup::WorldCat::Api::Record

  include Lookup::WorldCat::Shared::CreatorMethods
  include Lookup::WorldCat::Shared::DateMethods
  include Lookup::WorldCat::Shared::IdentifierMethods
  include Lookup::WorldCat::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many :dc_creator,     as: 'creator',      wrap: false
    has_many :dc_contributor, as: 'contributor',  wrap: false
    has_many :dc_date,        as: 'date',         wrap: false
    has_many :dc_description, as: 'description',  wrap: false
    has_many :dc_format,      as: 'format',       wrap: false
    has_many :dc_identifier,  as: 'identifier',   wrap: false
    has_many :dc_language,    as: 'language',     wrap: false
    has_many :dc_publisher,   as: 'publisher',    wrap: false
    has_many :dc_relation,    as: 'relation',     wrap: false
    has_many :dc_rights,      as: 'rights',       wrap: false
    has_many :dc_subject,     as: 'subject',      wrap: false
    has_many :dc_title,       as: 'title',        wrap: false
    has_one  :dc_type,        as: 'type',         wrap: false

    has_many :oclcterms_recordContentSource,      as: 'recordContentSource',      wrap: false if EXT
    has_one  :oclcterms_recordCreationDate,       as: 'recordCreationDate',       wrap: false if EXT
    has_one  :oclcterms_recordIdentifier,         as: 'recordIdentifier',         wrap: false
    has_one  :oclcterms_languageOfCataloging,     as: 'languageOfCataloging',     wrap: false if EXT
    has_one  :oclcterms_recordTranscribingAgency, as: 'recordTranscribingAgency', wrap: false if EXT
  end

end

__loading_end(__FILE__)
