# app/records/lookup/crossref/record/work_clinical_trial.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::Crossref::Record::WorkClinicalTrial
#
# @see https://api.crossref.org/swagger-ui/index.html#model-WorkClinicalTrial
#
#--
# noinspection LongLine
#++
class Lookup::Crossref::Record::WorkClinicalTrial < Lookup::Crossref::Api::Record

  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :clinical_trial_number
    has_one :registry
    has_one :type
  end

end

__loading_end(__FILE__)
