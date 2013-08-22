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

ActiveRecord::Schema.define(version: 20130822214330) do

  create_table "admins", force: true do |t|
    t.string   "email",                              null: false
    t.boolean  "can_change_admins",  default: false, null: false
    t.boolean  "can_create_surveys", default: false, null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.datetime "deleted_at"
    t.binary   "password_salt"
    t.binary   "password_hash"
  end

  add_index "admins", ["email"], name: "index_admins_on_email", unique: true, using: :btree

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "participants", force: true do |t|
    t.integer  "survey_id",                             null: false
    t.string   "phone_number",                          null: false
    t.boolean  "active",                 default: true, null: false
    t.string   "login_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "schedule"
    t.string   "time_zone"
    t.text     "question_chooser_state"
  end

  create_table "schedule_days", force: true do |t|
    t.integer  "participant_id",                 null: false
    t.date     "date",                           null: false
    t.text     "time_ranges"
    t.boolean  "skip",           default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "aasm_state"
  end

  add_index "schedule_days", ["aasm_state"], name: "index_schedule_days_on_aasm_state", using: :btree

  create_table "scheduled_questions", force: true do |t|
    t.integer  "schedule_day_id",    null: false
    t.integer  "survey_question_id", null: false
    t.datetime "scheduled_at",       null: false
    t.datetime "delivered_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "aasm_state"
  end

  add_index "scheduled_questions", ["aasm_state"], name: "index_scheduled_questions_on_aasm_state", using: :btree

  create_table "survey_permissions", force: true do |t|
    t.integer  "admin_id",          null: false
    t.integer  "survey_id",         null: false
    t.boolean  "can_modify_survey"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "survey_questions", force: true do |t|
    t.integer  "survey_id"
    t.string   "question_text", default: "", null: false
    t.integer  "position",      default: 0,  null: false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "surveys", force: true do |t|
    t.string   "name",                                         null: false
    t.integer  "samples_per_day",              default: 4,     null: false
    t.integer  "mean_minutes_between_samples", default: 60,    null: false
    t.integer  "sample_minutes_plusminus",     default: 15,    null: false
    t.boolean  "active",                       default: false, null: false
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.string   "twilio_account_sid"
    t.string   "twilio_auth_token"
    t.string   "phone_number"
    t.integer  "sampled_days",                 default: 1,     null: false
  end

  create_table "text_messages", force: true do |t|
    t.integer  "survey_id",       null: false
    t.string   "type",            null: false
    t.string   "from",            null: false
    t.string   "to",              null: false
    t.string   "message",         null: false
    t.text     "server_response"
    t.datetime "scheduled_at"
    t.datetime "delivered_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "text_messages", ["survey_id", "from"], name: "index_text_messages_on_survey_id_and_from", using: :btree
  add_index "text_messages", ["survey_id", "to"], name: "index_text_messages_on_survey_id_and_to", using: :btree
  add_index "text_messages", ["survey_id", "type"], name: "index_text_messages_on_survey_id_and_type", using: :btree

end
