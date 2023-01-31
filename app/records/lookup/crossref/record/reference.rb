# app/records/lookup/crossref/record/reference.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::Reference
#
# @see https://api.crossref.org/swagger-ui/index.html#model-Reference
#
class Lookup::Crossref::Record::Reference < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :article_title
    has_one :author
    has_one :component
    has_one :doi
    has_one :doi_asserted_by
    has_one :edition
    has_one :first_page
    has_one :isbn
    has_one :isbn_type
    has_one :issn
    has_one :issn_type
    has_one :issue
    has_one :journal_title
    has_one :key
    has_one :standard_designator
    has_one :standards_body
    has_one :unstructured
    has_one :volume
    has_one :volume_title
    has_one :year
  end

end

__loading_end(__FILE__)
