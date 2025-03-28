# app/models/upload.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A record of a download event.
#
class Download < ApplicationRecord

  include Model

  include Record
  include Record::Assignable
  include Record::Searchable
  include Record::Sortable

  include Download::SearchMethods

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.implicit_order_column = :created_at

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  belongs_to :user, optional: true

  has_one :org, through: :user

end

__loading_end(__FILE__)
