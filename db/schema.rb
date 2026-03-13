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

ActiveRecord::Schema[8.1].define(version: 2026_03_13_113000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.datetime "booked_at"
    t.string "class_name"
    t.datetime "class_time"
    t.datetime "created_at", null: false
    t.integer "mindbody_booking_id"
    t.boolean "status"
    t.bigint "studio_class_id"
    t.bigint "studio_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["studio_class_id"], name: "index_bookings_on_studio_class_id"
    t.index ["studio_id"], name: "index_bookings_on_studio_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "broadcasts", force: :cascade do |t|
    t.string "audience_filter"
    t.text "body"
    t.string "channel"
    t.datetime "created_at", null: false
    t.datetime "scheduled_at"
    t.datetime "sent_at"
    t.bigint "studio_id", null: false
    t.string "subject"
    t.integer "total_delivered"
    t.integer "total_failed"
    t.integer "total_sent"
    t.datetime "updated_at", null: false
    t.index ["studio_id"], name: "index_broadcasts_on_studio_id"
  end

  create_table "chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "status"
    t.bigint "studio_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["studio_id"], name: "index_chats_on_studio_id"
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "class_configs", force: :cascade do |t|
    t.string "class_name"
    t.datetime "created_at", null: false
    t.boolean "is_premium"
    t.integer "mindbody_class_id"
    t.integer "point_value"
    t.bigint "studio_id", null: false
    t.datetime "updated_at", null: false
    t.index ["studio_id"], name: "index_class_configs_on_studio_id"
  end

  create_table "deal_claims", force: :cascade do |t|
    t.boolean "active"
    t.datetime "claimed_at"
    t.string "code"
    t.datetime "created_at", null: false
    t.bigint "deal_id", null: false
    t.bigint "studio_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deal_id"], name: "index_deal_claims_on_deal_id"
    t.index ["studio_id"], name: "index_deal_claims_on_studio_id"
    t.index ["user_id"], name: "index_deal_claims_on_user_id"
  end

  create_table "deals", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.string "deal_type"
    t.integer "discount_percent"
    t.integer "expiry_days"
    t.string "name"
    t.bigint "studio_id", null: false
    t.string "trigger_condition"
    t.datetime "updated_at", null: false
    t.integer "usage_limit"
    t.index ["studio_id"], name: "index_deals_on_studio_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.string "content"
    t.datetime "created_at", null: false
    t.string "role"
    t.string "sentiment"
    t.string "summary"
    t.string "tag"
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
  end

  create_table "mindbody_clients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "mindbody_client_id"
    t.string "phone"
    t.bigint "studio_id", null: false
    t.datetime "updated_at", null: false
    t.index ["studio_id", "mindbody_client_id"], name: "index_mindbody_clients_on_studio_id_and_mindbody_client_id", unique: true
    t.index ["studio_id", "phone"], name: "index_mindbody_clients_on_studio_id_and_phone"
    t.index ["studio_id"], name: "index_mindbody_clients_on_studio_id"
  end

  create_table "mindbody_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "linked_at"
    t.json "match_data"
    t.string "mindbody_client_id"
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_mindbody_links_on_user_id"
  end

  create_table "notification_templates", force: :cascade do |t|
    t.string "body_template"
    t.datetime "created_at", null: false
    t.boolean "enabled"
    t.string "event_type"
    t.bigint "studio_id", null: false
    t.string "title_template"
    t.datetime "updated_at", null: false
    t.index ["studio_id"], name: "index_notification_templates_on_studio_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "body"
    t.datetime "created_at", null: false
    t.string "notification_type"
    t.string "path"
    t.datetime "read_at"
    t.datetime "sent_at"
    t.bigint "studio_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["studio_id"], name: "index_notifications_on_studio_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "phone_login_codes", force: :cascade do |t|
    t.integer "attempts_count", default: 0, null: false
    t.string "code_digest", null: false
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "phone_number", null: false
    t.bigint "studio_id", null: false
    t.datetime "updated_at", null: false
    t.index ["studio_id", "phone_number"], name: "index_phone_login_codes_on_studio_id_and_phone_number"
    t.index ["studio_id"], name: "index_phone_login_codes_on_studio_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth_key"
    t.datetime "created_at", null: false
    t.string "endpoint"
    t.string "p256dh_key"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "referrals", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "referral_code", null: false
    t.bigint "referred_id"
    t.bigint "referrer_id", null: false
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.index ["referral_code"], name: "index_referrals_on_referral_code", unique: true
    t.index ["referred_id"], name: "index_referrals_on_referred_id"
    t.index ["referrer_id"], name: "index_referrals_on_referrer_id"
  end

  create_table "reward_redemptions", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.integer "expiry_days"
    t.integer "point_spent"
    t.datetime "redeemed_at"
    t.bigint "reward_id", null: false
    t.boolean "status"
    t.bigint "studio_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["reward_id"], name: "index_reward_redemptions_on_reward_id"
    t.index ["studio_id"], name: "index_reward_redemptions_on_studio_id"
    t.index ["user_id"], name: "index_reward_redemptions_on_user_id"
  end

  create_table "rewards", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "image_url"
    t.string "name"
    t.integer "points_cost"
    t.integer "reward_type", default: 0, null: false
    t.bigint "studio_id", null: false
    t.datetime "updated_at", null: false
    t.index ["studio_id"], name: "index_rewards_on_studio_id"
  end

  create_table "studio_brands", force: :cascade do |t|
    t.string "background_color"
    t.string "brand_tone"
    t.datetime "created_at", null: false
    t.string "font_body"
    t.string "font_heading"
    t.string "logo_url"
    t.string "primary_color"
    t.string "raw_extraction"
    t.string "secondary_color"
    t.bigint "studio_id", null: false
    t.string "tagline"
    t.string "text_color"
    t.datetime "updated_at", null: false
    t.index ["studio_id"], name: "index_studio_brands_on_studio_id"
  end

  create_table "studio_classes", force: :cascade do |t|
    t.integer "capacity", default: 20
    t.bigint "class_config_id"
    t.string "class_type"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration_minutes", default: 60
    t.string "name"
    t.datetime "scheduled_at"
    t.integer "spots_taken", default: 0
    t.bigint "studio_id", null: false
    t.string "teacher_name"
    t.datetime "updated_at", null: false
    t.index ["class_config_id"], name: "index_studio_classes_on_class_config_id"
    t.index ["studio_id"], name: "index_studio_classes_on_studio_id"
  end

  create_table "studios", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.string "mindbody_api_key"
    t.string "mindbody_site_id"
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_studios_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.integer "available_points"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "last_visit_at"
    t.datetime "locked_at"
    t.integer "phone"
    t.string "phone_number"
    t.string "provider"
    t.string "referred_by"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.string "studio"
    t.integer "total_points"
    t.integer "total_visits"
    t.string "uid"
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "visits", force: :cascade do |t|
    t.bigint "class_config_id", null: false
    t.datetime "created_at", null: false
    t.integer "points_earned"
    t.bigint "studio_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.datetime "visited_at"
    t.index ["class_config_id"], name: "index_visits_on_class_config_id"
    t.index ["studio_id"], name: "index_visits_on_studio_id"
    t.index ["user_id"], name: "index_visits_on_user_id"
  end

  add_foreign_key "bookings", "studio_classes"
  add_foreign_key "bookings", "studios"
  add_foreign_key "bookings", "users"
  add_foreign_key "broadcasts", "studios"
  add_foreign_key "chats", "studios"
  add_foreign_key "chats", "users"
  add_foreign_key "class_configs", "studios"
  add_foreign_key "deal_claims", "deals"
  add_foreign_key "deal_claims", "studios"
  add_foreign_key "deal_claims", "users"
  add_foreign_key "deals", "studios"
  add_foreign_key "messages", "chats"
  add_foreign_key "mindbody_clients", "studios"
  add_foreign_key "mindbody_links", "users"
  add_foreign_key "notification_templates", "studios"
  add_foreign_key "notifications", "studios"
  add_foreign_key "notifications", "users"
  add_foreign_key "phone_login_codes", "studios"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "referrals", "users", column: "referred_id"
  add_foreign_key "referrals", "users", column: "referrer_id"
  add_foreign_key "reward_redemptions", "rewards"
  add_foreign_key "reward_redemptions", "studios"
  add_foreign_key "reward_redemptions", "users"
  add_foreign_key "rewards", "studios"
  add_foreign_key "studio_brands", "studios"
  add_foreign_key "studio_classes", "class_configs"
  add_foreign_key "studio_classes", "studios"
  add_foreign_key "studios", "users"
  add_foreign_key "visits", "class_configs"
  add_foreign_key "visits", "studios"
  add_foreign_key "visits", "users"
end
