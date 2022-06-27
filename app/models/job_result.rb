# app/models/job_result.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class JobResult < ApplicationRecord

  include JobMethods

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  # noinspection RailsParamDefResolve
  belongs_to :active_job, class_name: 'GoodJob::Job', optional: true

end

__loading_end(__FILE__)
