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

  has_many :artifacts

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # TODO: ???

end

__loading_end(__FILE__)
