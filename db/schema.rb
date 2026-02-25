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

ActiveRecord::Schema[8.1].define(version: 2026_02_25_174403) do
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

  create_table "addresses", force: :cascade do |t|
    t.integer "address_type"
    t.bigint "addressable_id", null: false
    t.string "addressable_type", null: false
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.boolean "is_primary"
    t.string "postal_code"
    t.string "state"
    t.string "street_line1"
    t.string "street_line2"
    t.datetime "updated_at", null: false
    t.index ["addressable_type", "addressable_id"], name: "index_addresses_on_addressable"
  end

  create_table "asset_assignments", force: :cascade do |t|
    t.bigint "assigned_to_id", null: false
    t.string "assigned_to_type", null: false
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.datetime "end_date"
    t.bigint "instance_id"
    t.text "notes"
    t.bigint "product_id", null: false
    t.string "purpose"
    t.datetime "returned_date"
    t.datetime "start_date"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["assigned_to_type", "assigned_to_id"], name: "index_asset_assignments_on_assigned_to"
    t.index ["instance_id"], name: "index_asset_assignments_on_instance_id"
    t.index ["product_id"], name: "index_asset_assignments_on_product_id"
  end

  create_table "asset_flags", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.text "description"
    t.string "icon"
    t.bigint "instance_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["instance_id"], name: "index_asset_flags_on_instance_id"
  end

  create_table "asset_group_products", force: :cascade do |t|
    t.bigint "asset_group_id", null: false
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_group_id"], name: "index_asset_group_products_on_asset_group_id"
    t.index ["product_id"], name: "index_asset_group_products_on_product_id"
  end

  create_table "asset_group_watchers", force: :cascade do |t|
    t.bigint "asset_group_id", null: false
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.boolean "notify_on_change"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["asset_group_id"], name: "index_asset_group_watchers_on_asset_group_id"
    t.index ["user_id"], name: "index_asset_group_watchers_on_user_id"
  end

  create_table "asset_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.text "description"
    t.bigint "instance_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["instance_id"], name: "index_asset_groups_on_instance_id"
  end

  create_table "asset_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "log_type"
    t.datetime "logged_at"
    t.jsonb "metadata"
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["product_id"], name: "index_asset_logs_on_product_id"
    t.index ["user_id"], name: "index_asset_logs_on_user_id"
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
    t.bigint "instance_id"
    t.text "invoice_notes"
    t.bigint "manager_id"
    t.text "notes"
    t.bigint "project_type_id"
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
    t.index ["instance_id", "status"], name: "index_bookings_on_instance_id_and_status"
    t.index ["instance_id"], name: "index_bookings_on_instance_id"
    t.index ["manager_id"], name: "index_bookings_on_manager_id"
    t.index ["project_type_id"], name: "index_bookings_on_project_type_id"
    t.index ["reference_number"], name: "index_bookings_on_reference_number", unique: true
    t.index ["start_date", "end_date"], name: "index_bookings_on_start_date_and_end_date"
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["venue_location_id"], name: "index_bookings_on_venue_location_id"
  end

  create_table "business_entities", force: :cascade do |t|
    t.boolean "active"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.string "entity_type"
    t.bigint "instance_id"
    t.string "legal_name"
    t.string "name"
    t.text "notes"
    t.string "tax_id"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_business_entities_on_client_id"
    t.index ["instance_id"], name: "index_business_entities_on_instance_id"
  end

  create_table "clients", force: :cascade do |t|
    t.integer "account_value_cents"
    t.string "account_value_currency", default: "USD"
    t.text "address"
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.string "email"
    t.bigint "instance_id"
    t.string "name", null: false
    t.text "notes"
    t.string "phone"
    t.integer "position"
    t.integer "priority", default: 1
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["archived"], name: "index_clients_on_archived"
    t.index ["deleted"], name: "index_clients_on_deleted"
    t.index ["email"], name: "index_clients_on_email"
    t.index ["instance_id", "archived"], name: "index_clients_on_instance_id_and_archived"
    t.index ["instance_id"], name: "index_clients_on_instance_id"
  end

  create_table "comment_upvotes", force: :cascade do |t|
    t.bigint "comment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["comment_id"], name: "index_comment_upvotes_on_comment_id"
    t.index ["user_id"], name: "index_comment_upvotes_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "commentable_id", null: false
    t.string "commentable_type", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.bigint "instance_id", null: false
    t.bigint "parent_comment_id"
    t.datetime "updated_at", null: false
    t.integer "upvotes_count"
    t.bigint "user_id", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["instance_id"], name: "index_comments_on_instance_id"
    t.index ["parent_comment_id"], name: "index_comments_on_parent_comment_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "email_queues", force: :cascade do |t|
    t.integer "attempts"
    t.text "body"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.bigint "instance_id", null: false
    t.datetime "last_attempt_at"
    t.jsonb "metadata"
    t.string "recipient"
    t.datetime "sent_at"
    t.integer "status"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["instance_id"], name: "index_email_queues_on_instance_id"
  end

  create_table "instances", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.string "name"
    t.bigint "owner_id"
    t.jsonb "settings"
    t.string "subdomain"
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_instances_on_owner_id"
  end

  create_table "invitation_codes", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.integer "current_uses"
    t.boolean "deleted"
    t.datetime "expires_at"
    t.bigint "instance_id", null: false
    t.integer "max_uses"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_invitation_codes_on_created_by_id"
    t.index ["instance_id"], name: "index_invitation_codes_on_instance_id"
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
    t.bigint "instance_id"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_kits_on_active"
    t.index ["instance_id"], name: "index_kits_on_instance_id"
  end

  create_table "locations", force: :cascade do |t|
    t.text "address"
    t.boolean "archived", default: false, null: false
    t.string "barcode"
    t.bigint "client_id"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.bigint "instance_id"
    t.string "name", null: false
    t.text "notes"
    t.bigint "parent_id"
    t.datetime "updated_at", null: false
    t.index ["archived"], name: "index_locations_on_archived"
    t.index ["barcode"], name: "index_locations_on_barcode", unique: true
    t.index ["client_id"], name: "index_locations_on_client_id"
    t.index ["deleted"], name: "index_locations_on_deleted"
    t.index ["instance_id"], name: "index_locations_on_instance_id"
    t.index ["parent_id"], name: "index_locations_on_parent_id"
  end

  create_table "maintenance_jobs", force: :cascade do |t|
    t.bigint "assigned_to_id"
    t.datetime "completed_date"
    t.integer "cost_cents"
    t.string "cost_currency"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.text "description"
    t.bigint "instance_id"
    t.text "notes"
    t.integer "priority"
    t.bigint "product_id", null: false
    t.datetime "scheduled_date"
    t.integer "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_maintenance_jobs_on_assigned_to_id"
    t.index ["instance_id"], name: "index_maintenance_jobs_on_instance_id"
    t.index ["product_id"], name: "index_maintenance_jobs_on_product_id"
  end

  create_table "manufacturers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "instance_id"
    t.string "name", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["instance_id"], name: "index_manufacturers_on_instance_id"
    t.index ["name"], name: "index_manufacturers_on_name"
  end

  create_table "notes", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.bigint "notable_id", null: false
    t.string "notable_type", null: false
    t.integer "note_type"
    t.boolean "pinned"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["notable_type", "notable_id"], name: "index_notes_on_notable"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.string "amount_currency", default: "USD", null: false
    t.bigint "booking_id", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.bigint "instance_id"
    t.datetime "payment_date", default: -> { "CURRENT_TIMESTAMP" }
    t.string "payment_method"
    t.integer "payment_type", null: false
    t.integer "quantity", default: 1, null: false
    t.string "reference"
    t.string "supplier"
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_payments_on_booking_id"
    t.index ["deleted"], name: "index_payments_on_deleted"
    t.index ["instance_id"], name: "index_payments_on_instance_id"
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["payment_type"], name: "index_payments_on_payment_type"
  end

  create_table "permission_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.bigint "instance_id", null: false
    t.string "name"
    t.jsonb "permissions"
    t.datetime "updated_at", null: false
    t.index ["instance_id"], name: "index_permission_groups_on_instance_id"
  end

  create_table "positions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.text "description"
    t.bigint "instance_id", null: false
    t.string "name"
    t.integer "rank"
    t.datetime "updated_at", null: false
    t.index ["instance_id"], name: "index_positions_on_instance_id"
  end

  create_table "product_asset_flags", force: :cascade do |t|
    t.bigint "asset_flag_id", null: false
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_flag_id"], name: "index_product_asset_flags_on_asset_flag_id"
    t.index ["product_id"], name: "index_product_asset_flags_on_product_id"
  end

  create_table "product_types", force: :cascade do |t|
    t.boolean "archived", default: false
    t.string "category"
    t.string "color"
    t.datetime "created_at", null: false
    t.jsonb "custom_fields", default: {}
    t.integer "daily_price_cents", default: 0, null: false
    t.string "daily_price_currency", default: "USD", null: false
    t.text "description"
    t.decimal "discount_percentage", precision: 5, scale: 2
    t.bigint "instance_id"
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
    t.index ["instance_id"], name: "index_product_types_on_instance_id"
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
    t.bigint "instance_id"
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
    t.index ["instance_id", "active"], name: "index_products_on_instance_id_and_active"
    t.index ["instance_id"], name: "index_products_on_instance_id"
    t.index ["product_type_id"], name: "index_products_on_product_type_id"
    t.index ["storage_location_id"], name: "index_products_on_storage_location_id"
  end

  create_table "project_types", force: :cascade do |t|
    t.boolean "active"
    t.boolean "auto_confirm"
    t.datetime "created_at", null: false
    t.integer "default_duration_days"
    t.boolean "deleted"
    t.text "description"
    t.jsonb "feature_flags"
    t.bigint "instance_id"
    t.string "name"
    t.boolean "requires_approval"
    t.jsonb "settings"
    t.datetime "updated_at", null: false
    t.index ["instance_id"], name: "index_project_types_on_instance_id"
  end

  create_table "sales_tasks", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "completed_date"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.text "description"
    t.datetime "due_date"
    t.bigint "instance_id"
    t.integer "priority"
    t.integer "status"
    t.integer "task_type"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["client_id"], name: "index_sales_tasks_on_client_id"
    t.index ["instance_id"], name: "index_sales_tasks_on_instance_id"
    t.index ["user_id"], name: "index_sales_tasks_on_user_id"
  end

  create_table "staff_applications", force: :cascade do |t|
    t.datetime "applied_at"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.text "notes"
    t.datetime "reviewed_at"
    t.bigint "reviewer_id"
    t.bigint "staff_role_id", null: false
    t.integer "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["reviewer_id"], name: "index_staff_applications_on_reviewer_id"
    t.index ["staff_role_id"], name: "index_staff_applications_on_staff_role_id"
    t.index ["user_id"], name: "index_staff_applications_on_user_id"
  end

  create_table "staff_assignments", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.datetime "end_date"
    t.text "notes"
    t.bigint "staff_role_id", null: false
    t.datetime "start_date"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["booking_id"], name: "index_staff_assignments_on_booking_id"
    t.index ["staff_role_id"], name: "index_staff_assignments_on_staff_role_id"
    t.index ["user_id"], name: "index_staff_assignments_on_user_id"
  end

  create_table "staff_roles", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.text "description"
    t.integer "filled_count"
    t.bigint "instance_id"
    t.string "name"
    t.integer "required_count"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_staff_roles_on_booking_id"
    t.index ["instance_id"], name: "index_staff_roles_on_instance_id"
  end

  create_table "user_certifications", force: :cascade do |t|
    t.string "certificate_number"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.date "expiry_date"
    t.date "issued_date"
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_certifications_on_user_id"
  end

  create_table "user_positions", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.datetime "end_date"
    t.bigint "instance_id", null: false
    t.bigint "position_id", null: false
    t.datetime "start_date"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["instance_id"], name: "index_user_positions_on_instance_id"
    t.index ["position_id"], name: "index_user_positions_on_position_id"
    t.index ["user_id"], name: "index_user_positions_on_user_id"
  end

  create_table "user_preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "preferences"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.jsonb "widgets"
    t.index ["user_id"], name: "index_user_preferences_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "api_token"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "email_verified_at"
    t.bigint "instance_id"
    t.string "name", null: false
    t.string "password_digest", null: false
    t.bigint "permission_group_id"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.jsonb "social_links"
    t.boolean "suspended", default: false
    t.datetime "suspended_at"
    t.text "suspended_reason"
    t.datetime "updated_at", null: false
    t.string "verification_token"
    t.index ["api_token"], name: "index_users_on_api_token", unique: true, where: "(api_token IS NOT NULL)"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["instance_id"], name: "index_users_on_instance_id"
    t.index ["permission_group_id"], name: "index_users_on_permission_group_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["verification_token"], name: "index_users_on_verification_token", unique: true
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
    t.bigint "instance_id"
    t.text "notes"
    t.datetime "notified_at"
    t.integer "quantity", default: 1, null: false
    t.datetime "start_date", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["bookable_type", "bookable_id"], name: "index_waitlist_entries_on_bookable"
    t.index ["bookable_type", "bookable_id"], name: "index_waitlist_entries_on_bookable_type_and_bookable_id"
    t.index ["customer_email"], name: "index_waitlist_entries_on_customer_email"
    t.index ["instance_id"], name: "index_waitlist_entries_on_instance_id"
    t.index ["status"], name: "index_waitlist_entries_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "asset_assignments", "instances"
  add_foreign_key "asset_assignments", "products"
  add_foreign_key "asset_flags", "instances"
  add_foreign_key "asset_group_products", "asset_groups"
  add_foreign_key "asset_group_products", "products"
  add_foreign_key "asset_group_watchers", "asset_groups"
  add_foreign_key "asset_group_watchers", "users"
  add_foreign_key "asset_groups", "instances"
  add_foreign_key "asset_logs", "products"
  add_foreign_key "asset_logs", "users"
  add_foreign_key "booking_comments", "bookings"
  add_foreign_key "booking_comments", "users"
  add_foreign_key "booking_line_items", "bookings"
  add_foreign_key "bookings", "clients"
  add_foreign_key "bookings", "instances"
  add_foreign_key "bookings", "locations", column: "venue_location_id"
  add_foreign_key "bookings", "project_types"
  add_foreign_key "bookings", "users", column: "manager_id"
  add_foreign_key "business_entities", "clients"
  add_foreign_key "business_entities", "instances"
  add_foreign_key "clients", "instances"
  add_foreign_key "comment_upvotes", "comments"
  add_foreign_key "comment_upvotes", "users"
  add_foreign_key "comments", "comments", column: "parent_comment_id"
  add_foreign_key "comments", "instances"
  add_foreign_key "comments", "users"
  add_foreign_key "email_queues", "instances"
  add_foreign_key "instances", "users", column: "owner_id"
  add_foreign_key "invitation_codes", "instances"
  add_foreign_key "invitation_codes", "users", column: "created_by_id"
  add_foreign_key "kit_items", "kits"
  add_foreign_key "kit_items", "products"
  add_foreign_key "kits", "instances"
  add_foreign_key "locations", "clients"
  add_foreign_key "locations", "instances"
  add_foreign_key "locations", "locations", column: "parent_id"
  add_foreign_key "maintenance_jobs", "instances"
  add_foreign_key "maintenance_jobs", "products"
  add_foreign_key "maintenance_jobs", "users", column: "assigned_to_id"
  add_foreign_key "manufacturers", "instances"
  add_foreign_key "notes", "users"
  add_foreign_key "payments", "bookings"
  add_foreign_key "payments", "instances"
  add_foreign_key "permission_groups", "instances"
  add_foreign_key "positions", "instances"
  add_foreign_key "product_asset_flags", "asset_flags"
  add_foreign_key "product_asset_flags", "products"
  add_foreign_key "product_types", "instances"
  add_foreign_key "product_types", "manufacturers"
  add_foreign_key "products", "instances"
  add_foreign_key "products", "locations", column: "storage_location_id"
  add_foreign_key "products", "product_types"
  add_foreign_key "project_types", "instances"
  add_foreign_key "sales_tasks", "clients"
  add_foreign_key "sales_tasks", "instances"
  add_foreign_key "sales_tasks", "users"
  add_foreign_key "staff_applications", "staff_roles"
  add_foreign_key "staff_applications", "users"
  add_foreign_key "staff_applications", "users", column: "reviewer_id"
  add_foreign_key "staff_assignments", "bookings"
  add_foreign_key "staff_assignments", "staff_roles"
  add_foreign_key "staff_assignments", "users"
  add_foreign_key "staff_roles", "bookings"
  add_foreign_key "staff_roles", "instances"
  add_foreign_key "user_certifications", "users"
  add_foreign_key "user_positions", "instances"
  add_foreign_key "user_positions", "positions"
  add_foreign_key "user_positions", "users"
  add_foreign_key "user_preferences", "users"
  add_foreign_key "users", "instances"
  add_foreign_key "users", "permission_groups"
  add_foreign_key "waitlist_entries", "instances"
end
