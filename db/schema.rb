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

ActiveRecord::Schema[7.0].define(version: 2023_02_15_171943) do
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phase_id"], name: "index_actions_on_phase_id"
    t.index ["user_id"], name: "index_actions_on_user_id"
  end

  create_table "artifacts", force: :cascade do |t|
    t.string "format"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entries", force: :cascade do |t|
    t.bigint "user_id"
    t.string "submission_id"
    t.string "repository"
    t.string "fmt"
    t.string "ext"
    t.json "emma_data"
    t.json "file_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_entries_on_user_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at", precision: nil
    t.datetime "performed_at", precision: nil
    t.datetime "finished_at", precision: nil
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at", precision: nil
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at", unique: true
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "job_results", force: :cascade do |t|
    t.uuid "active_job_id"
    t.jsonb "output"
    t.jsonb "error"
    t.jsonb "diagnostic"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_job_results_on_active_job_id"
  end

  create_table "manifest_items", force: :cascade do |t|
    t.uuid "manifest_id"
    t.integer "row", default: 0
    t.integer "delta", default: 0
    t.boolean "editing"
    t.boolean "deleting"
    t.datetime "last_saved", precision: nil
    t.datetime "last_lookup", precision: nil
    t.datetime "last_submit", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "data_status"
    t.string "file_status"
    t.string "ready_status"
    t.json "file_data"
    t.string "repository"
    t.date "emma_publicationDate"
    t.string "dc_title"
    t.string "emma_version"
    t.string "bib_seriesType"
    t.string "bib_series"
    t.string "bib_seriesPosition"
    t.string "dc_publisher"
    t.text "dc_creator"
    t.text "dc_identifier"
    t.text "dc_relation"
    t.string "dc_language", array: true
    t.string "dc_rights"
    t.text "dc_description"
    t.text "dc_subject"
    t.string "dc_type"
    t.string "dc_format"
    t.string "emma_formatFeature", array: true
    t.date "dcterms_dateAccepted"
    t.string "dcterms_dateCopyright"
    t.string "rem_source"
    t.text "rem_metadataSource"
    t.text "rem_remediatedBy"
    t.boolean "rem_complete"
    t.text "rem_coverage"
    t.string "rem_remediatedAspects", array: true
    t.string "rem_textQuality"
    t.string "rem_status"
    t.date "rem_remediationDate"
    t.text "rem_comments"
    t.string "s_accessibilityFeature", array: true
    t.string "s_accessibilityControl", array: true
    t.string "s_accessibilityHazard", array: true
    t.string "s_accessMode", array: true
    t.string "s_accessModeSufficient", array: true
    t.text "s_accessibilitySummary"
    t.jsonb "backup"
    t.datetime "last_indexed", precision: nil
    t.string "submission_id"
    t.index ["manifest_id"], name: "index_manifest_items_on_manifest_id"
  end

  create_table "manifests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_manifests_on_user_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "emailAddress"
    t.boolean "institutional"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bulk_id"], name: "index_phases_on_bulk_id"
    t.index ["entry_id", "type"], name: "index_phases_on_entry_id_and_type"
    t.index ["entry_id"], name: "index_phases_on_entry_id"
    t.index ["user_id"], name: "index_phases_on_user_id"
  end

  create_table "reading_lists", force: :cascade do |t|
    t.string "readingListId"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", precision: nil
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phase"
    t.string "edit_state"
    t.string "edit_user"
    t.text "edit_file_data"
    t.text "edit_emma_data"
    t.datetime "edited_at", precision: nil
    t.string "review_user"
    t.boolean "review_success"
    t.text "review_comment"
    t.datetime "reviewed_at", precision: nil
    t.index ["user_id"], name: "index_uploads_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "access_token"
    t.string "refresh_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
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
