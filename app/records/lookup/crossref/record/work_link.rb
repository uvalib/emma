# app/records/lookup/crossref/record/work_link.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorkLink
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorkLink
#
class Lookup::Crossref::Record::WorkLink < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :content_type
    has_one :content_version
    has_one :intended_application
    has_one :url
  end

end

__loading_end(__FILE__)
