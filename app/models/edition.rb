# app/models/edition.rb
#
# frozen_string_literal: true
# warn_indent:           true
#

__loading_begin(__FILE__)

# Model for a periodical edition.
#
class Edition < ApplicationRecord

  belongs_to :periodical, optional: true

  has_and_belongs_to_many :artifacts
  has_and_belongs_to_many :reading_lists

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  resourcify

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # TODO: ???

end

__loading_end(__FILE__)
