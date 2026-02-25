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

ActiveRecord::Schema[8.1].define(version: 2026_02_25_085617) do
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

  create_table "booking_line_items", force: :cascade do |t|
    t.bigint "bookable_id", null: false
    t.string "bookable_type", null: false
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.integer "days", default: 1, null: false
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "NGN", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["bookable_type", "bookable_id"], name: "index_booking_line_items_on_bookable"
    t.index ["bookable_type", "bookable_id"], name: "index_booking_line_items_on_bookable_type_and_bookable_id"
    t.index ["booking_id"], name: "index_booking_line_items_on_booking_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "customer_email", null: false
    t.string "customer_name", null: false
    t.string "customer_phone"
    t.datetime "end_date", null: false
    t.text "notes"
    t.string "reference_number"
    t.datetime "start_date", null: false
    t.integer "status", default: 0, null: false
    t.integer "total_price_cents", default: 0, null: false
    t.string "total_price_currency", default: "NGN", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_email"], name: "index_bookings_on_customer_email"
    t.index ["reference_number"], name: "index_bookings_on_reference_number", unique: true
    t.index ["start_date", "end_date"], name: "index_bookings_on_start_date_and_end_date"
    t.index ["status"], name: "index_bookings_on_status"
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
    t.string "daily_price_currency", default: "NGN", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_kits_on_active"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "barcode"
    t.string "category"
    t.datetime "created_at", null: false
    t.integer "daily_price_cents", default: 0, null: false
    t.string "daily_price_currency", default: "NGN", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "quantity", default: 1, null: false
    t.string "serial_numbers", default: [], array: true
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_products_on_active"
    t.index ["barcode"], name: "index_products_on_barcode", unique: true, where: "(barcode IS NOT NULL)"
    t.index ["category"], name: "index_products_on_category"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "booking_line_items", "bookings"
  add_foreign_key "kit_items", "kits"
  add_foreign_key "kit_items", "products"
end
