# db/migrate/*_add_reviewer_to_uploads.rb
#
# frozen_string_literal: true
# warn_indent:           true

class AddReviewerToUploads < ActiveRecord::Migration[6.0]

  def change
    add_column :uploads, :review_user,    :string
    add_column :uploads, :review_success, :boolean
    add_column :uploads, :review_comment, :text
    add_column :uploads, :reviewed_at,    :timestamp
  end

end
