# db/migrate/*_create_action_text_tables.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Copied from $GEM_HOME/gems/actiontext-7.1.0/db/migrate/20180528164100_create_action_text_tables.rb
# and adjusted per https://edgeguides.rubyonrails.org/action_text_overview.html
#
# NOTE: With Rails 7.1, it became necessary to add this in order to get tests
#   execute. This schema (and table) are not used for `RAILS_ENV=production`
#   but are apparently necessary for FixtureSet which is required for
#   `RAILS_ENV=test`.

class CreateActionTextTables < ActiveRecord::Migration[6.0]

  def change
=begin # NOTE: original from generator
    # Use Active Record's configured type for primary and foreign keys
    primary_key_type, foreign_key_type = primary_and_foreign_key_types
=end
    primary_key_type = foreign_key_type = :uuid

    create_table :action_text_rich_texts, id: primary_key_type do |t|
      t.string     :name, null: false
      t.text       :body, size: :long
      t.references :record, null: false, polymorphic: true, index: false, type: foreign_key_type

      t.timestamps

      t.index [ :record_type, :record_id, :name ], name: "index_action_text_rich_texts_uniqueness", unique: true
    end
  end

=begin # NOTE: original from generator
  private

  def primary_and_foreign_key_types
    config = Rails.configuration.generators
    setting = config.options[config.orm][:primary_key_type]
    primary_key_type = setting || :primary_key
    foreign_key_type = setting || :bigint
    [primary_key_type, foreign_key_type]
  end
=end

end
