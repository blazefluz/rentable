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

ActiveRecord::Schema[8.1].define(version: 2026_02_25_163123) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "booking_comments", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["booking_id"], name: "index_booking_comments_on_booking_id"
    t.index ["created_at"], name: "index_booking_comments_on_created_at"
    t.index ["deleted"], name: "index_booking_comments_on_deleted"
    t.index ["user_id"], name: "index_booking_comments_on_user_id"
  end

  create_table "booking_line_items", force: :cascade do |t|
    t.bigint "bookable_id", null: false
    t.string "bookable_type", null: false
    t.bigint "booking_id", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "days", default: 1, null: false
    t.boolean "deleted", default: false, null: false
    t.decimal "discount_percent", precision: 5, scale: 2, default: "0.0"
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.integer "workflow_status", default: 0, null: false
    t.index ["bookable_type", "bookable_id"], name: "index_booking_line_items_on_bookable"
    t.index ["bookable_type", "bookable_id"], name: "index_booking_line_items_on_bookable_type_and_bookable_id"
    t.index ["booking_id"], name: "index_booking_line_items_on_booking_id"
    t.index ["deleted"], name: "index_booking_line_items_on_deleted"
    t.index ["workflow_status"], name: "index_booking_line_items_on_workflow_status"
  end

  create_table "bookings", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.bigint "client_id"
    t.datetime "created_at", null: false
    t.string "customer_email", null: false
    t.string "customer_name", null: false
    t.string "customer_phone"
    t.decimal "default_discount", precision: 5, scale: 2, default: "0.0"
    t.boolean "deleted", default: false, null: false
    t.datetime "delivery_end_date"
    t.datetime "delivery_start_date"
    t.datetime "end_date", null: false
    t.text "invoice_notes"
    t.bigint "manager_id"
    t.text "notes"
    t.string "reference_number"
    t.datetime "start_date", null: false
    t.integer "status", default: 0, null: false
    t.integer "total_price_cents", default: 0, null: false
    t.string "total_price_currency", default: "USD", null: false
    t.datetime "updated_at", null: false
    t.bigint "venue_location_id"
    t.index ["archived"], name: "index_bookings_on_archived"
    t.index ["client_id"], name: "index_bookings_on_client_id"
    t.index ["customer_email"], name: "index_bookings_on_customer_email"
    t.index ["deleted"], name: "index_bookings_on_deleted"
    t.index ["delivery_start_date", "delivery_end_date"], name: "index_bookings_on_delivery_start_date_and_delivery_end_date"
    t.index ["manager_id"], name: "index_bookings_on_manager_id"
    t.index ["reference_number"], name: "index_bookings_on_reference_number", unique: true
    t.index ["start_date", "end_date"], name: "index_bookings_on_start_date_and_end_date"
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["venue_location_id"], name: "index_bookings_on_venue_location_id"
  end

  create_table "clients", force: :cascade do |t|
    t.text "address"
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.string "email"
    t.string "name", null: false
    t.text "notes"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["archived"], name: "index_clients_on_archived"
    t.index ["deleted"], name: "index_clients_on_deleted"
    t.index ["email"], name: "index_clients_on_email"
  end

  create_table "kit_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "kit_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["kit_id", "product_id"], name: "index_kit_items_on_kit_id_and_product_id", unique: true
    t.index ["kit_id"], name: "index_kit_items_on_kit_id"
    t.index ["product_id"], name: "index_kit_items_on_product_id"
  end

  create_table "kits", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.integer "daily_price_cents", default: 0, null: false
    t.string "daily_price_currency", default: "USD", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_kits_on_active"
  end

  create_table "locations", force: :cascade do |t|
    t.text "address"
    t.boolean "archived", default: false, null: false
    t.bigint "client_id"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.string "name", null: false
    t.text "notes"
    t.bigint "parent_id"
    t.datetime "updated_at", null: false
    t.index ["archived"], name: "index_locations_on_archived"
    t.index ["client_id"], name: "index_locations_on_client_id"
    t.index ["deleted"], name: "index_locations_on_deleted"
    t.index ["parent_id"], name: "index_locations_on_parent_id"
  end

  create_table "manufacturers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["name"], name: "index_manufacturers_on_name"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.string "amount_currency", default: "USD", null: false
    t.bigint "booking_id", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "payment_date", default: -> { "CURRENT_TIMESTAMP" }
    t.string "payment_method"
    t.integer "payment_type", null: false
    t.integer "quantity", default: 1, null: false
    t.string "reference"
    t.string "supplier"
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_payments_on_booking_id"
    t.index ["deleted"], name: "index_payments_on_deleted"
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["payment_type"], name: "index_payments_on_payment_type"
  end

  create_table "product_types", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.jsonb "custom_fields", default: {}
    t.integer "daily_price_cents", default: 0, null: false
    t.string "daily_price_currency", default: "USD", null: false
    t.text "description"
    t.bigint "manufacturer_id"
    t.decimal "mass", precision: 10, scale: 2
    t.string "name", null: false
    t.string "product_link"
    t.datetime "updated_at", null: false
    t.integer "value_cents", default: 0, null: false
    t.integer "weekly_price_cents", default: 0, null: false
    t.string "weekly_price_currency", default: "USD", null: false
    t.index ["category"], name: "index_product_types_on_category"
    t.index ["custom_fields"], name: "index_product_types_on_custom_fields", using: :gin
    t.index ["manufacturer_id"], name: "index_product_types_on_manufacturer_id"
    t.index ["name"], name: "index_product_types_on_name"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true
    t.boolean "archived", default: false, null: false
    t.string "asset_tag"
    t.string "barcode"
    t.string "category"
    t.datetime "created_at", null: false
    t.jsonb "custom_fields", default: {}
    t.integer "daily_price_cents", default: 0, null: false
    t.string "daily_price_currency", default: "USD", null: false
    t.boolean "deleted", default: false, null: false
    t.text "description"
    t.datetime "end_date"
    t.decimal "mass", precision: 10, scale: 2
    t.string "name", null: false
    t.bigint "product_type_id"
    t.integer "quantity", default: 1, null: false
    t.string "serial_numbers", default: [], array: true
    t.boolean "show_public", default: true, null: false
    t.bigint "storage_location_id"
    t.datetime "updated_at", null: false
    t.integer "value_cents", default: 0, null: false
    t.integer "weekly_price_cents", default: 0, null: false
    t.string "weekly_price_currency", default: "USD", null: false
    t.index ["active"], name: "index_products_on_active"
    t.index ["archived"], name: "index_products_on_archived"
    t.index ["asset_tag"], name: "index_products_on_asset_tag", unique: true, where: "(asset_tag IS NOT NULL)"
    t.index ["barcode"], name: "index_products_on_barcode", unique: true, where: "(barcode IS NOT NULL)"
    t.index ["category"], name: "index_products_on_category"
    t.index ["custom_fields"], name: "index_products_on_custom_fields", using: :gin
    t.index ["deleted"], name: "index_products_on_deleted"
    t.index ["product_type_id"], name: "index_products_on_product_type_id"
    t.index ["storage_location_id"], name: "index_products_on_storage_location_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "api_token"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true, where: "(api_token IS NOT NULL)"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.text "object_changes"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "waitlist_entries", force: :cascade do |t|
    t.bigint "bookable_id", null: false
    t.string "bookable_type", null: false
    t.datetime "created_at", null: false
    t.string "customer_email", null: false
    t.string "customer_name", null: false
    t.string "customer_phone"
    t.datetime "end_date", null: false
    t.text "notes"
    t.datetime "notified_at"
    t.integer "quantity", default: 1, null: false
    t.datetime "start_date", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["bookable_type", "bookable_id"], name: "index_waitlist_entries_on_bookable"
    t.index ["bookable_type", "bookable_id"], name: "index_waitlist_entries_on_bookable_type_and_bookable_id"
    t.index ["customer_email"], name: "index_waitlist_entries_on_customer_email"
    t.index ["status"], name: "index_waitlist_entries_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "booking_comments", "bookings"
  add_foreign_key "booking_comments", "users"
  add_foreign_key "booking_line_items", "bookings"
  add_foreign_key "bookings", "clients"
  add_foreign_key "bookings", "locations", column: "venue_location_id"
  add_foreign_key "bookings", "users", column: "manager_id"
  add_foreign_key "kit_items", "kits"
  add_foreign_key "kit_items", "products"
  add_foreign_key "locations", "clients"
  add_foreign_key "locations", "locations", column: "parent_id"
  add_foreign_key "payments", "bookings"
  add_foreign_key "product_types", "manufacturers"
  add_foreign_key "products", "locations", column: "storage_location_id"
  add_foreign_key "products", "product_types"
end
