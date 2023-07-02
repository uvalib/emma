# app/records/lookup/crossref/record/work.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Metadata record schema for an item lookup.
#
# @see https://api.crossref.org/swagger-ui/index.html#model-Work
#
#--
# noinspection LongLine
#++
class Lookup::Crossref::Record::Work < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CreatorMethods
  include Lookup::Crossref::Shared::DateMethods
  include Lookup::Crossref::Shared::IdentifierMethods
  include Lookup::Crossref::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one  :abstract
    has_one  :accepted,               Lookup::Crossref::Record::DateParts
    has_many :alternative_id                                                      if EXT
    has_one  :approved,               Lookup::Crossref::Record::DateParts
    has_many :archive                                                             if EXT
    has_one  :article_number
    has_many :assertion,              Lookup::Crossref::Record::WorkAssertion     if ALL
    has_many :author,                 Lookup::Crossref::Record::Author
    has_many :chair,                  Lookup::Crossref::Record::Author            if EXT
    has_many :clinical_trial_number,  Lookup::Crossref::Record::WorkClinicalTrial if EXT
    has_one  :component_number
    has_many :container_title
    has_one  :content_created,        Lookup::Crossref::Record::DateParts
    has_one  :content_domain,         Lookup::Crossref::Record::WorkDomain        if EXT
    has_one  :content_updated,        Lookup::Crossref::Record::DateParts         if EXT
    has_one  :created,                Lookup::Crossref::Record::Date              if EXT
    has_one  :degree
    has_one  :deposited,              Lookup::Crossref::Record::Date              if ALL
    has_one  :doi                                                                 if EXT
    has_one  :edition_number
    has_many :editor,                 Lookup::Crossref::Record::Author
    has_one  :free_to_read,           Lookup::Crossref::Record::WorkFreeToRead    if EXT
    has_many :funder,                 Lookup::Crossref::Record::WorkFunder        if EXT
    has_one  :group_title
    has_one  :indexed,                Lookup::Crossref::Record::Date              if ALL
    has_one  :institution,            Lookup::Crossref::Record::WorkInstitution
    has_one  :is_referenced_by_count, Integer                                     if ALL
    has_many :isbn
    has_many :isbn_type,              Lookup::Crossref::Record::WorkIssnType
    has_many :issn
    has_many :issn_type,              Lookup::Crossref::Record::WorkIssnType
    has_one  :issue
    has_one  :issued,                 Lookup::Crossref::Record::DateParts
    has_one  :journal_issue,          Lookup::Crossref::Record::WorkJournalIssue
    has_one  :language
    has_many :license,                Lookup::Crossref::Record::WorkLicense       if EXT
    has_many :link,                   Lookup::Crossref::Record::WorkLink          if EXT
    has_one  :member                                                              if ALL
    has_many :original_title
    has_one  :page
    has_one  :part_number
    has_one  :posted,                 Lookup::Crossref::Record::DateParts
    has_one  :prefix                                                              if EXT
    has_one  :published,              Lookup::Crossref::Record::DateParts
    has_one  :published_online,       Lookup::Crossref::Record::DateParts
    has_one  :published_other,        Lookup::Crossref::Record::DateParts
    has_one  :published_print,        Lookup::Crossref::Record::DateParts
    has_one  :publisher
    has_one  :publisher_location
    has_one  :reference,              Lookup::Crossref::Record::Reference         if ALL # NOTE: [1]
    has_one  :reference_count,        Integer                                     if ALL
    has_one  :references_count,       Integer                                     if ALL
    has_one  :relation                                                            if ALL # NOTE: [1]
    has_one  :review,                 Lookup::Crossref::Record::WorkReview        if EXT
    has_one  :score,                  Integer                                     if EXT
    has_one  :short_container_title                                               if EXT
    has_many :short_title
    has_one  :source                                                              if EXT
    has_many :standards_body,         Lookup::Crossref::Record::WorkStandardsBody
    has_many :subject
    has_many :subtitle
    has_one  :subtype
    has_many :title
    has_many :translator,             Lookup::Crossref::Record::Author
    has_one  :type
    has_one  :update_policy                                                       if EXT
    has_many :update_to,              Lookup::Crossref::Record::WorkUpdate        if EXT
    has_one  :url                                                                 if EXT
    has_one  :volume

    # === Observed but not documented

#   has_one  :resource,               Hash

  end
  # NOTE[1]: Not helpful and potentially so large that it can be problematic.

end

__loading_end(__FILE__)
