# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_11_12_140000) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "actions", force: :cascade do |t|
    t.bigint "phase_id"
    t.bigint "user_id"
    t.string "command"
    t.string "type"
    t.string "state"
    t.string "condition"
    t.string "action"
    t.text "report"
    t.integer "retries", default: 0
    t.json "emma_data"
    t.json "file_data"
    t.string "file_source"
    t.integer "checksum"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["phase_id"], name: "index_actions_on_phase_id"
    t.index ["user_id"], name: "index_actions_on_user_id"
  end

  create_table "artifacts", force: :cascade do |t|
    t.string "format"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "entry_type"
    t.bigint "entry_id"
    t.index ["entry_type", "entry_id"], name: "index_artifacts_on_entry_type_and_entry_id"
  end

  create_table "artifacts_editions", id: false, force: :cascade do |t|
    t.bigint "artifact_id", null: false
    t.bigint "edition_id", null: false
    t.index ["artifact_id", "edition_id"], name: "index_artifacts_editions_on_artifact_id_and_edition_id"
  end

  create_table "artifacts_titles", id: false, force: :cascade do |t|
    t.bigint "artifact_id", null: false
    t.bigint "title_id", null: false
    t.index ["artifact_id", "title_id"], name: "index_artifacts_titles_on_artifact_id_and_title_id"
  end

  create_table "editions", force: :cascade do |t|
    t.string "editionId"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "periodical_id"
    t.index ["periodical_id"], name: "index_editions_on_periodical_id"
  end

  create_table "editions_periodicals", id: false, force: :cascade do |t|
    t.bigint "edition_id", null: false
    t.bigint "periodical_id", null: false
    t.index ["edition_id", "periodical_id"], name: "index_editions_periodicals_on_edition_id_and_periodical_id"
  end

  create_table "editions_reading_lists", id: false, force: :cascade do |t|
    t.bigint "edition_id", null: false
    t.bigint "reading_list_id", null: false
    t.index ["edition_id", "reading_list_id"], name: "index_editions_reading_lists_on_edition_id_and_reading_list_id"
  end

  create_table "emma_statuses", force: :cascade do |t|
    t.string "item"
    t.string "value"
    t.boolean "active"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "entries", force: :cascade do |t|
    t.bigint "user_id"
    t.string "submission_id"
    t.string "repository"
    t.string "fmt"
    t.string "ext"
    t.json "emma_data"
    t.json "file_data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_entries_on_user_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "emailAddress"
    t.boolean "institutional"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "members_reading_lists", id: false, force: :cascade do |t|
    t.bigint "member_id", null: false
    t.bigint "reading_list_id", null: false
    t.index ["member_id", "reading_list_id"], name: "index_members_reading_lists_on_member_id_and_reading_list_id"
  end

  create_table "periodicals", force: :cascade do |t|
    t.string "seriesId"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "phases", force: :cascade do |t|
    t.bigint "entry_id"
    t.bigint "user_id"
    t.bigint "bulk_id"
    t.string "command"
    t.string "type"
    t.string "state"
    t.text "remarks"
    t.string "submission_id"
    t.string "repository"
    t.string "fmt"
    t.string "ext"
    t.json "emma_data"
    t.json "file_data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["bulk_id"], name: "index_phases_on_bulk_id"
    t.index ["entry_id", "type"], name: "index_phases_on_entry_id_and_type"
    t.index ["entry_id"], name: "index_phases_on_entry_id"
    t.index ["user_id"], name: "index_phases_on_user_id"
  end

  create_table "reading_lists", force: :cascade do |t|
    t.string "readingListId"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_reading_lists_on_user_id"
  end

  create_table "reading_lists_titles", id: false, force: :cascade do |t|
    t.bigint "reading_list_id", null: false
    t.bigint "title_id", null: false
    t.index ["reading_list_id", "title_id"], name: "index_reading_lists_titles_on_reading_list_id_and_title_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource_type_and_resource_id"
  end

  create_table "search_calls", force: :cascade do |t|
    t.json "query"
    t.json "filter"
    t.json "sort"
    t.json "page"
    t.json "result"
    t.bigint "user_id"
    t.datetime "created_at"
    t.index ["user_id"], name: "index_search_calls_on_user_id"
  end

  create_table "search_calls_results", id: false, force: :cascade do |t|
    t.bigint "search_call_id", null: false
    t.bigint "search_result_id", null: false
    t.index ["search_call_id", "search_result_id"], name: "index_searches_on_call_id_and_result_id"
  end

  create_table "search_results", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "format"
    t.string "formatVersion"
    t.string "identifier"
    t.string "repository"
    t.string "repositoryRecordId"
  end

  create_table "titles", force: :cascade do |t|
    t.string "bookshareId"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "uploads", force: :cascade do |t|
    t.text "file_data"
    t.text "emma_data"
    t.bigint "user_id"
    t.string "repository"
    t.string "submission_id"
    t.string "fmt"
    t.string "ext"
    t.string "state"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "phase"
    t.string "edit_state"
    t.string "edit_user"
    t.text "edit_file_data"
    t.text "edit_emma_data"
    t.datetime "edited_at"
    t.string "review_user"
    t.boolean "review_success"
    t.text "review_comment"
    t.datetime "reviewed_at"
    t.index ["user_id"], name: "index_uploads_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "first_name"
    t.string "last_name"
    t.string "access_token"
    t.string "refresh_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.bigint "effective_id"
    t.index ["effective_id"], name: "index_users_on_effective_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  add_foreign_key "phases", "phases", column: "bulk_id"
end
