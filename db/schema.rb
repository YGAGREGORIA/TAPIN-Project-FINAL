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

ActiveRecord::Schema[8.1].define(version: 2026_03_10_225601) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.datetime "booked_at"
    t.string "class_name"
    t.datetime "class_time"
    t.datetime "created_at", null: false
    t.integer "mindbody_booking_id"
    t.boolean "status"
    t.bigint "studio_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["studio_id"], name: "index_bookings_on_studio_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "status"
    t.bigint "studio_id", null: false
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
    t.datetime "claimed_at"
    t.string "code"
    t.datetime "created_at", null: false
    t.bigint "deal_id", null: false
    t.boolean "status"
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
    t.integer "available_points"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "last_visit_at"
    t.integer "phone"
    t.string "referred_by"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "total_points"
    t.integer "total_visits"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
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

  add_foreign_key "bookings", "studios"
  add_foreign_key "bookings", "users"
  add_foreign_key "chats", "studios"
  add_foreign_key "chats", "users"
  add_foreign_key "class_configs", "studios"
  add_foreign_key "deal_claims", "deals"
  add_foreign_key "deal_claims", "studios"
  add_foreign_key "deal_claims", "users"
  add_foreign_key "deals", "studios"
  add_foreign_key "messages", "chats"
  add_foreign_key "reward_redemptions", "rewards"
  add_foreign_key "reward_redemptions", "studios"
  add_foreign_key "reward_redemptions", "users"
  add_foreign_key "rewards", "studios"
  add_foreign_key "studio_brands", "studios"
  add_foreign_key "studios", "users"
  add_foreign_key "visits", "class_configs"
  add_foreign_key "visits", "studios"
  add_foreign_key "visits", "users"
end
