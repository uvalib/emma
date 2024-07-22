# db/migrate/*_create_action_mailbox_tables.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Copied from $GEM_HOME/gems/actionmailbox-7.1.0/db/migrate/20180917164000_create_action_mailbox_tables.rb
# and adjusted per https://edgeguides.rubyonrails.org/action_text_overview.html
#
# NOTE: With Rails 7.1, it became necessary to add this in order to get tests
#   execute. This schema (and table) are not used for `RAILS_ENV=production`
#   but are apparently necessary for FixtureSet which is required for
#   `RAILS_ENV=test`.

class CreateActionMailboxTables < ActiveRecord::Migration[6.0]

  def change

    primary_key_type = :uuid

    create_table :action_mailbox_inbound_emails, id: primary_key_type do |t|
      t.integer :status, default: 0, null: false
      t.string  :message_id, null: false
      t.string  :message_checksum, null: false

      t.timestamps

      t.index [ :message_id, :message_checksum ], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
    end

  end

=begin
  private

  def primary_key_type
    config = Rails.configuration.generators
    config.options[config.orm][:primary_key_type] || :primary_key
  end
=end

end
