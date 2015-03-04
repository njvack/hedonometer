# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150304220344) do

  create_table "admins", force: :cascade do |t|
    t.string   "email",             limit: 255,                   null: false
    t.boolean  "can_change_admins", limit: 1,     default: false, null: false
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.datetime "deleted_at"
    t.binary   "password_salt",     limit: 65535
    t.binary   "password_hash",     limit: 65535
  end

  add_index "admins", ["email"], name: "index_admins_on_email", unique: true, using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0, null: false
    t.integer  "attempts",   limit: 4,     default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "participants", force: :cascade do |t|
    t.integer  "survey_id",              limit: 4,                    null: false
    t.string   "phone_number",           limit: 255,                  null: false
    t.boolean  "active",                 limit: 1,     default: true, null: false
    t.string   "login_code",             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "time_zone",              limit: 255
    t.text     "question_chooser_state", limit: 65535
    t.string   "external_key",           limit: 255
  end

  create_table "schedule_days", force: :cascade do |t|
    t.integer  "participant_id", limit: 4,                     null: false
    t.date     "date",                                         null: false
    t.text     "time_ranges",    limit: 65535
    t.boolean  "skip",           limit: 1,     default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "aasm_state",     limit: 255
  end

  add_index "schedule_days", ["aasm_state"], name: "index_schedule_days_on_aasm_state", using: :btree

  create_table "scheduled_questions", force: :cascade do |t|
    t.integer  "schedule_day_id",    limit: 4,   null: false
    t.integer  "survey_question_id", limit: 4,   null: false
    t.datetime "scheduled_at",                   null: false
    t.datetime "delivered_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "aasm_state",         limit: 255
  end

  add_index "scheduled_questions", ["aasm_state"], name: "index_scheduled_questions_on_aasm_state", using: :btree

  create_table "survey_permissions", force: :cascade do |t|
    t.integer  "admin_id",          limit: 4, null: false
    t.integer  "survey_id",         limit: 4, null: false
    t.boolean  "can_modify_survey", limit: 1
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "survey_questions", force: :cascade do |t|
    t.integer  "survey_id",     limit: 4
    t.string   "question_text", limit: 255, default: "", null: false
    t.integer  "position",      limit: 4,   default: 0,  null: false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "surveys", force: :cascade do |t|
    t.string   "name",                         limit: 255,                                                                       null: false
    t.integer  "samples_per_day",              limit: 4,     default: 4,                                                         null: false
    t.integer  "mean_minutes_between_samples", limit: 4,     default: 60,                                                        null: false
    t.integer  "sample_minutes_plusminus",     limit: 4,     default: 15,                                                        null: false
    t.boolean  "active",                       limit: 1,     default: false,                                                     null: false
    t.datetime "created_at",                                                                                                     null: false
    t.datetime "updated_at",                                                                                                     null: false
    t.string   "twilio_account_sid",           limit: 255
    t.string   "twilio_auth_token",            limit: 255
    t.string   "phone_number",                 limit: 255
    t.integer  "sampled_days",                 limit: 4,     default: 1,                                                         null: false
    t.string   "time_zone",                    limit: 255
    t.text     "help_message",                 limit: 65535
    t.string   "welcome_message",              limit: 255,   default: "Welcome to the study! Quit at any time by texting STOP.", null: false
  end

  add_index "surveys", ["phone_number", "active"], name: "index_surveys_on_phone_number_and_active", using: :btree

  create_table "text_messages", force: :cascade do |t|
    t.integer  "survey_id",       limit: 4,     null: false
    t.string   "type",            limit: 255,   null: false
    t.string   "from_number",     limit: 255,   null: false
    t.string   "to_number",       limit: 255,   null: false
    t.string   "message",         limit: 255,   null: false
    t.text     "server_response", limit: 65535
    t.datetime "scheduled_at"
    t.datetime "delivered_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "text_messages", ["survey_id", "from_number"], name: "index_text_messages_on_survey_id_and_from_number", using: :btree
  add_index "text_messages", ["survey_id", "to_number"], name: "index_text_messages_on_survey_id_and_to_number", using: :btree
  add_index "text_messages", ["survey_id", "type"], name: "index_text_messages_on_survey_id_and_type", using: :btree

end
