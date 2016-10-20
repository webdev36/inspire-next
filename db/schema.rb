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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150916065856) do

  create_table "actions", :force => true do |t|
    t.string   "type"
    t.text     "as_text"
    t.datetime "deleted_at"
    t.integer  "actionable_id"
    t.string   "actionable_type"
  end

  create_table "channel_groups", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "user_id"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.string   "tparty_keyword"
    t.string   "keyword"
    t.integer  "default_channel_id"
    t.text     "moderator_emails"
    t.boolean  "real_time_update"
    t.datetime "deleted_at"
    t.boolean  "web_signup",         :default => false
  end

  add_index "channel_groups", ["user_id"], :name => "index_channel_groups_on_user_id"

  create_table "channels", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "user_id"
    t.string   "type"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.string   "keyword"
    t.string   "tparty_keyword"
    t.datetime "next_send_time"
    t.text     "schedule"
    t.integer  "channel_group_id"
    t.string   "one_word"
    t.string   "suffix"
    t.text     "moderator_emails"
    t.boolean  "real_time_update"
    t.datetime "deleted_at"
    t.boolean  "relative_schedule"
    t.boolean  "send_only_once",           :default => false
    t.boolean  "active",                   :default => true
    t.boolean  "allow_mo_subscription",    :default => true
    t.datetime "mo_subscription_deadline"
  end

  add_index "channels", ["user_id"], :name => "index_channels_on_user_id"

  create_table "message_options", :force => true do |t|
    t.integer  "message_id"
    t.string   "key"
    t.string   "value"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "messages", :force => true do |t|
    t.text     "title"
    t.text     "caption"
    t.string   "type"
    t.integer  "channel_id"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
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
  end

  add_index "messages", ["channel_id"], :name => "index_messages_on_channel_id"

  create_table "rails_admin_histories", :force => true do |t|
    t.text     "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      :limit => 2
    t.integer  "year",       :limit => 8
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], :name => "index_rails_admin_histories"

  create_table "response_actions", :force => true do |t|
    t.string   "response_text"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "message_id"
    t.datetime "deleted_at"
  end

  create_table "subscriber_activities", :force => true do |t|
    t.integer  "subscriber_id"
    t.integer  "channel_id"
    t.integer  "message_id"
    t.string   "type"
    t.string   "origin"
    t.text     "title"
    t.text     "caption"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "channel_group_id"
    t.boolean  "processed"
    t.datetime "deleted_at"
    t.string   "tparty_identifier"
    t.text     "options"
  end

  add_index "subscriber_activities", ["channel_id"], :name => "index_subscriber_activities_on_channel_id"
  add_index "subscriber_activities", ["message_id"], :name => "index_subscriber_activities_on_message_id"
  add_index "subscriber_activities", ["subscriber_id"], :name => "index_subscriber_activities_on_subscriber_id"

  create_table "subscribers", :force => true do |t|
    t.string   "name"
    t.string   "phone_number"
    t.text     "remarks"
    t.integer  "last_msg_seq_no"
    t.integer  "user_id"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.string   "email"
    t.datetime "deleted_at"
    t.text     "additional_attributes"
  end

  add_index "subscribers", ["user_id"], :name => "index_subscribers_on_user_id"

  create_table "subscriptions", :force => true do |t|
    t.integer  "channel_id"
    t.integer  "subscriber_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.datetime "deleted_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "",    :null => false
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0,     :null => false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.boolean  "admin",                  :default => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
