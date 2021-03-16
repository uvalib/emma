# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_02_07_220010) do

  create_table "artifacts", charset: "utf8", force: :cascade do |t|
    t.string "format"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "entry_type"
    t.integer "entry_id"
    t.index ["entry_type", "entry_id"], name: "index_artifacts_on_entry_type_and_entry_id"
  end

  create_table "artifacts_editions", id: false, charset: "utf8", force: :cascade do |t|
    t.integer "artifact_id", null: false
    t.integer "edition_id", null: false
    t.index ["artifact_id", "edition_id"], name: "index_artifacts_editions_on_artifact_id_and_edition_id"
  end

  create_table "artifacts_titles", id: false, charset: "utf8", force: :cascade do |t|
    t.integer "artifact_id", null: false
    t.integer "title_id", null: false
    t.index ["artifact_id", "title_id"], name: "index_artifacts_titles_on_artifact_id_and_title_id"
  end

  create_table "editions", charset: "utf8", force: :cascade do |t|
    t.string "editionId"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "periodical_id"
    t.index ["periodical_id"], name: "index_editions_on_periodical_id"
  end

  create_table "editions_periodicals", id: false, charset: "utf8", force: :cascade do |t|
    t.integer "edition_id", null: false
    t.integer "periodical_id", null: false
    t.index ["edition_id", "periodical_id"], name: "index_editions_periodicals_on_edition_id_and_periodical_id"
  end

  create_table "editions_reading_lists", id: false, charset: "utf8", force: :cascade do |t|
    t.integer "edition_id", null: false
    t.integer "reading_list_id", null: false
    t.index ["edition_id", "reading_list_id"], name: "index_editions_reading_lists_on_edition_id_and_reading_list_id"
  end

  create_table "members", charset: "utf8", force: :cascade do |t|
    t.string "emailAddress"
    t.boolean "institutional"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "members_reading_lists", id: false, charset: "utf8", force: :cascade do |t|
    t.integer "member_id", null: false
    t.integer "reading_list_id", null: false
    t.index ["member_id", "reading_list_id"], name: "index_members_reading_lists_on_member_id_and_reading_list_id"
  end

  create_table "periodicals", charset: "utf8", force: :cascade do |t|
    t.string "seriesId"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "reading_lists", charset: "utf8", force: :cascade do |t|
    t.string "readingListId"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_reading_lists_on_user_id"
  end

  create_table "reading_lists_titles", id: false, charset: "utf8", force: :cascade do |t|
    t.integer "reading_list_id", null: false
    t.integer "title_id", null: false
    t.index ["reading_list_id", "title_id"], name: "index_reading_lists_titles_on_reading_list_id_and_title_id"
  end

  create_table "roles", charset: "utf8", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.integer "resource_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource_type_and_resource_id"
  end

  create_table "search_calls", charset: "utf8", force: :cascade do |t|
    t.json "query"
    t.json "filter"
    t.json "sort"
    t.json "page"
    t.json "result"
    t.bigint "user_id"
    t.datetime "created_at"
    t.index ["user_id"], name: "index_search_calls_on_user_id"
  end

  create_table "search_calls_results", id: false, charset: "utf8", force: :cascade do |t|
    t.bigint "search_call_id", null: false
    t.bigint "search_result_id", null: false
    t.index ["search_call_id", "search_result_id"], name: "index_searches_on_call_id_and_result_id"
  end

  create_table "search_results", charset: "utf8", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "format"
    t.string "formatVersion"
    t.string "identifier"
    t.string "repository"
    t.string "repositoryRecordId"
  end

  create_table "titles", charset: "utf8", force: :cascade do |t|
    t.string "bookshareId"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "uploads", charset: "utf8", force: :cascade do |t|
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
    t.timestamp "edited_at"
    t.string "review_user"
    t.boolean "review_success"
    t.text "review_comment"
    t.timestamp "reviewed_at"
    t.index ["user_id"], name: "index_uploads_on_user_id"
  end

  create_table "users", charset: "utf8", force: :cascade do |t|
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, charset: "utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

end
