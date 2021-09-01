# app/models/artifact.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model for an artifact (i.e., an instance of remediated content).
#
class Artifact < ApplicationRecord

  include Model

  include Record
  include Record::Authorizable

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  # noinspection RailsParamDefResolve
  belongs_to :entry, polymorphic: true, optional: true

end

__loading_end(__FILE__)
