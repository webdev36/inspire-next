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

ActiveRecord::Schema.define(version: 20161129152546) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "actions", force: :cascade do |t|
    t.string   "type"
    t.text     "as_text"
    t.datetime "deleted_at"
    t.integer  "actionable_id"
    t.string   "actionable_type"
    t.text     "data"
  end

  create_table "channel_groups", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tparty_keyword"
    t.string   "keyword"
    t.integer  "default_channel_id"
    t.text     "moderator_emails"
    t.boolean  "real_time_update"
    t.datetime "deleted_at"
    t.boolean  "web_signup",         default: false
  end

  add_index "channel_groups", ["user_id"], name: "index_channel_groups_on_user_id", using: :btree

  create_table "channels", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "user_id"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "keyword"
    t.string   "tparty_keyword"
    t.text     "schedule"
    t.datetime "next_send_time"
    t.integer  "channel_group_id"
    t.string   "one_word"
    t.string   "suffix"
    t.text     "moderator_emails"
    t.boolean  "real_time_update"
    t.datetime "deleted_at"
    t.boolean  "relative_schedule"
    t.boolean  "send_only_once",           default: false
    t.boolean  "active",                   default: true
    t.boolean  "allow_mo_subscription",    default: true
    t.datetime "mo_subscription_deadline"
  end

  add_index "channels", ["user_id"], name: "index_channels_on_user_id", using: :btree

  create_table "chatroom_chatters", force: :cascade do |t|
    t.integer  "chatroom_id"
    t.integer  "chatter_id"
    t.string   "chatter_type"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "chatroom_chatters", ["chatroom_id"], name: "index_chatroom_chatters_on_chatroom_id", using: :btree
  add_index "chatroom_chatters", ["chatter_type", "chatter_id"], name: "index_chatroom_chatters_on_chatter_type_and_chatter_id", using: :btree

  create_table "chatrooms", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "user_id"
    t.string   "tparty_keyword"
  end

  create_table "chats", force: :cascade do |t|
    t.integer  "chatroom_id"
    t.integer  "chatter_id"
    t.string   "chatter_type"
    t.text     "body"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "chats", ["chatroom_id"], name: "index_chats_on_chatroom_id", using: :btree
  add_index "chats", ["chatter_type", "chatter_id"], name: "index_chats_on_chatter_type_and_chatter_id", using: :btree

  create_table "message_options", force: :cascade do |t|
    t.integer  "message_id"
    t.string   "key"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", force: :cascade do |t|
    t.text     "title"
    t.text     "caption"
    t.string   "type"
    t.integer  "channel_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "content_file_name"
    t.string   "content_content_type"
    t.integer  "content_file_size"
    t.datetime "content_updated_at"
    t.integer  "seq_no"
    t.datetime "next_send_time"
    t.boolean  "primary"
    t.text     "reminder_message_text"
    t.integer  "reminder_delay"
    t.text     "repeat_reminder_message_text"
    t.integer  "repeat_reminder_delay"
    t.integer  "number_of_repeat_reminders"
    t.text     "options"
    t.datetime "deleted_at"
    t.text     "schedule"
    t.boolean  "active"
    t.boolean  "requires_response"
    t.text     "recurring_schedule"
  end

  add_index "messages", ["channel_id"], name: "index_messages_on_channel_id", using: :btree

  create_table "rails_admin_histories", force: :cascade do |t|
    t.text     "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      limit: 2
    t.integer  "year",       limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], name: "index_rails_admin_histories", using: :btree

  create_table "response_actions", force: :cascade do |t|
    t.string   "response_text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "message_id"
    t.datetime "deleted_at"
  end

  create_table "rule_activities", force: :cascade do |t|
    t.integer  "rule_id"
    t.boolean  "success"
    t.text     "message"
    t.text     "data"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "ruleable_id"
    t.string   "ruleable_type"
  end

  add_index "rule_activities", ["ruleable_type", "ruleable_id"], name: "index_rule_activities_on_ruleable_type_and_ruleable_id", using: :btree

  create_table "rules", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "priority"
    t.integer  "user_id"
    t.text     "rule_if"
    t.text     "rule_then"
    t.datetime "next_run_at"
    t.boolean  "system",      default: false
    t.boolean  "active",      default: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.text     "selection"
  end

  add_index "rules", ["user_id", "name"], name: "index_rules_on_user_id_and_name", using: :btree

  create_table "subscriber_activities", force: :cascade do |t|
    t.integer  "subscriber_id"
    t.integer  "channel_id"
    t.integer  "message_id"
    t.string   "type"
    t.string   "origin"
    t.text     "title"
    t.text     "caption"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "channel_group_id"
    t.boolean  "processed"
    t.datetime "deleted_at"
    t.string   "tparty_identifier"
    t.text     "options"
    t.integer  "user_id"
  end

  add_index "subscriber_activities", ["channel_id"], name: "index_subscriber_activities_on_channel_id", using: :btree
  add_index "subscriber_activities", ["message_id"], name: "index_subscriber_activities_on_message_id", using: :btree
  add_index "subscriber_activities", ["subscriber_id"], name: "index_subscriber_activities_on_subscriber_id", using: :btree

  create_table "subscribers", force: :cascade do |t|
    t.string   "name"
    t.string   "phone_number"
    t.text     "remarks"
    t.integer  "last_msg_seq_no"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.datetime "deleted_at"
    t.text     "additional_attributes"
    t.text     "data"
    t.string   "chat_name"
  end

  add_index "subscribers", ["user_id"], name: "index_subscribers_on_user_id", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "channel_id"
    t.integer  "subscriber_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",                  default: false
    t.string   "chat_name"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  add_foreign_key "chatroom_chatters", "chatrooms"
  add_foreign_key "chats", "chatrooms"
end
