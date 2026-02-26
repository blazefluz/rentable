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

ActiveRecord::Schema[8.1].define(version: 2026_02_26_173251) do
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
    t.bigint "company_id"
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
    t.index ["company_id"], name: "index_addresses_on_company_id"
  end

  create_table "asset_assignments", force: :cascade do |t|
    t.bigint "assigned_to_id", null: false
    t.string "assigned_to_type", null: false
    t.bigint "company_id"
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
    t.index ["company_id"], name: "index_asset_assignments_on_company_id"
    t.index ["instance_id"], name: "index_asset_assignments_on_instance_id"
    t.index ["product_id"], name: "index_asset_assignments_on_product_id"
  end

  create_table "asset_flags", force: :cascade do |t|
    t.string "color"
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.text "description"
    t.string "icon"
    t.bigint "instance_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_asset_flags_on_company_id"
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
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.text "description"
    t.bigint "instance_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_asset_groups_on_company_id"
    t.index ["instance_id"], name: "index_asset_groups_on_instance_id"
  end

  create_table "asset_logs", force: :cascade do |t|
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "log_type"
    t.datetime "logged_at"
    t.jsonb "metadata"
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["company_id"], name: "index_asset_logs_on_company_id"
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

  create_table "booking_line_item_instances", force: :cascade do |t|
    t.bigint "booking_line_item_id", null: false
    t.datetime "created_at", null: false
    t.bigint "product_instance_id", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_line_item_id", "product_instance_id"], name: "index_booking_line_item_instances_unique", unique: true
    t.index ["booking_line_item_id"], name: "index_booking_line_item_instances_on_booking_line_item_id"
    t.index ["product_instance_id"], name: "index_booking_line_item_instances_on_product_instance_id"
  end

  create_table "booking_line_items", force: :cascade do |t|
    t.datetime "actual_return_date"
    t.bigint "bookable_id", null: false
    t.string "bookable_type", null: false
    t.bigint "booking_id", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "days", default: 1, null: false
    t.integer "days_overdue", default: 0
    t.boolean "deleted", default: false, null: false
    t.datetime "delivered_at"
    t.bigint "delivered_by_id"
    t.string "delivery_carrier"
    t.integer "delivery_cost_cents", default: 0
    t.string "delivery_cost_currency", default: "USD"
    t.datetime "delivery_end_date"
    t.bigint "delivery_location_id"
    t.integer "delivery_method", default: 0
    t.text "delivery_notes"
    t.datetime "delivery_start_date"
    t.integer "delivery_status", default: 0
    t.string "delivery_tracking_number"
    t.decimal "discount_percent", precision: 5, scale: 2, default: "0.0"
    t.datetime "expected_return_date"
    t.bigint "fulfillment_location_id"
    t.datetime "late_fee_calculated_at"
    t.integer "late_fee_cents", default: 0
    t.string "late_fee_currency", default: "USD"
    t.bigint "location_transfer_id"
    t.datetime "overdue_notified_at"
    t.datetime "picked_at"
    t.bigint "pickup_location_id"
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "ready_for_pickup_at"
    t.boolean "requires_transfer", default: false
    t.datetime "signature_captured_at"
    t.boolean "signature_required", default: false
    t.integer "tax_amount_cents"
    t.string "tax_amount_currency"
    t.bigint "tax_rate_id"
    t.boolean "taxable"
    t.integer "transfer_status", default: 0
    t.datetime "updated_at", null: false
    t.integer "workflow_status", default: 0, null: false
    t.index ["actual_return_date"], name: "index_booking_line_items_on_actual_return_date"
    t.index ["bookable_type", "bookable_id"], name: "index_booking_line_items_on_bookable"
    t.index ["bookable_type", "bookable_id"], name: "index_booking_line_items_on_bookable_type_and_bookable_id"
    t.index ["booking_id"], name: "index_booking_line_items_on_booking_id"
    t.index ["days_overdue"], name: "index_booking_line_items_on_days_overdue"
    t.index ["deleted"], name: "index_booking_line_items_on_deleted"
    t.index ["delivered_by_id"], name: "index_booking_line_items_on_delivered_by_id"
    t.index ["delivery_location_id"], name: "index_booking_line_items_on_delivery_location_id"
    t.index ["delivery_method"], name: "index_booking_line_items_on_delivery_method"
    t.index ["delivery_start_date"], name: "index_booking_line_items_on_delivery_start_date"
    t.index ["delivery_status"], name: "index_booking_line_items_on_delivery_status"
    t.index ["delivery_tracking_number"], name: "index_booking_line_items_on_delivery_tracking_number"
    t.index ["expected_return_date", "actual_return_date"], name: "index_line_items_on_return_dates"
    t.index ["expected_return_date"], name: "index_booking_line_items_on_expected_return_date"
    t.index ["fulfillment_location_id"], name: "index_booking_line_items_on_fulfillment_location_id"
    t.index ["location_transfer_id"], name: "index_booking_line_items_on_location_transfer_id"
    t.index ["pickup_location_id"], name: "index_booking_line_items_on_pickup_location_id"
    t.index ["requires_transfer"], name: "index_booking_line_items_on_requires_transfer"
    t.index ["transfer_status"], name: "index_booking_line_items_on_transfer_status"
    t.index ["workflow_status"], name: "index_booking_line_items_on_workflow_status"
  end

  create_table "booking_templates", force: :cascade do |t|
    t.boolean "archived", default: false
    t.jsonb "booking_data", default: {}
    t.string "category"
    t.bigint "client_id"
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.boolean "deleted", default: false
    t.text "description"
    t.integer "estimated_duration_days", default: 1
    t.boolean "favorite", default: false
    t.boolean "is_public", default: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.string "tags", default: [], array: true
    t.integer "template_type", default: 0, null: false
    t.string "thumbnail_url"
    t.datetime "updated_at", null: false
    t.integer "usage_count", default: 0
    t.index ["archived"], name: "index_booking_templates_on_archived"
    t.index ["category"], name: "index_booking_templates_on_category"
    t.index ["client_id", "deleted"], name: "index_booking_templates_on_client_id_and_deleted"
    t.index ["client_id"], name: "index_booking_templates_on_client_id"
    t.index ["company_id"], name: "index_booking_templates_on_company_id"
    t.index ["created_by_id", "deleted"], name: "index_booking_templates_on_created_by_id_and_deleted"
    t.index ["created_by_id"], name: "index_booking_templates_on_created_by_id"
    t.index ["deleted"], name: "index_booking_templates_on_deleted"
    t.index ["favorite"], name: "index_booking_templates_on_favorite"
    t.index ["is_public"], name: "index_booking_templates_on_is_public"
    t.index ["tags"], name: "index_booking_templates_on_tags", using: :gin
    t.index ["template_type"], name: "index_booking_templates_on_template_type"
  end

  create_table "bookings", force: :cascade do |t|
    t.integer "aging_bucket", default: 0
    t.boolean "archived", default: false, null: false
    t.string "campaign_id"
    t.integer "cancellation_deadline_hours", default: 168
    t.decimal "cancellation_fee_percentage", precision: 5, scale: 2, default: "0.0"
    t.integer "cancellation_policy", default: 0, null: false
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.bigint "cancelled_by_id"
    t.bigint "client_id"
    t.bigint "collection_assigned_to_id"
    t.text "collection_notes"
    t.integer "collection_status", default: 0
    t.bigint "company_id"
    t.boolean "converted_from_quote", default: false
    t.datetime "created_at", null: false
    t.string "customer_email", null: false
    t.string "customer_name", null: false
    t.string "customer_phone"
    t.integer "days_past_due", default: 0
    t.decimal "default_discount", precision: 5, scale: 2, default: "0.0"
    t.bigint "default_tax_rate_id"
    t.boolean "deleted", default: false, null: false
    t.datetime "delivery_end_date"
    t.datetime "delivery_start_date"
    t.datetime "end_date", null: false
    t.integer "grand_total_cents"
    t.string "grand_total_currency"
    t.bigint "instance_id"
    t.text "invoice_notes"
    t.datetime "last_payment_reminder_sent_at"
    t.bigint "lead_id"
    t.string "lead_source"
    t.bigint "manager_id"
    t.text "notes"
    t.date "payment_due_date"
    t.integer "payment_reminder_count", default: 0
    t.bigint "project_type_id"
    t.datetime "quote_approved_at"
    t.bigint "quote_approved_by_id"
    t.text "quote_decline_reason"
    t.datetime "quote_declined_at"
    t.datetime "quote_expires_at"
    t.string "quote_number"
    t.datetime "quote_sent_at"
    t.integer "quote_status", default: 0
    t.text "quote_terms"
    t.integer "quote_valid_days", default: 30
    t.datetime "quote_viewed_at"
    t.bigint "recurring_booking_id"
    t.string "reference_number"
    t.string "referral_code"
    t.integer "refund_amount_cents", default: 0
    t.string "refund_amount_currency", default: "USD"
    t.datetime "refund_processed_at"
    t.integer "refund_status", default: 0
    t.boolean "reverse_charge_applied"
    t.integer "security_deposit_cents"
    t.string "security_deposit_currency", default: "USD"
    t.datetime "security_deposit_refunded_at"
    t.integer "security_deposit_status", default: 0
    t.datetime "start_date", null: false
    t.integer "status", default: 0, null: false
    t.integer "subtotal_cents"
    t.string "subtotal_currency"
    t.boolean "tax_exempt"
    t.string "tax_exempt_certificate"
    t.text "tax_exempt_reason"
    t.boolean "tax_override"
    t.integer "tax_override_amount_cents"
    t.bigint "tax_override_by_id"
    t.text "tax_override_reason"
    t.integer "tax_total_cents"
    t.string "tax_total_currency"
    t.integer "total_price_cents", default: 0, null: false
    t.string "total_price_currency", default: "USD", null: false
    t.datetime "updated_at", null: false
    t.string "utm_campaign"
    t.string "utm_medium"
    t.string "utm_source"
    t.bigint "venue_location_id"
    t.index ["aging_bucket"], name: "index_bookings_on_aging_bucket"
    t.index ["archived"], name: "index_bookings_on_archived"
    t.index ["cancellation_policy"], name: "index_bookings_on_cancellation_policy"
    t.index ["cancelled_at"], name: "index_bookings_on_cancelled_at"
    t.index ["cancelled_by_id"], name: "index_bookings_on_cancelled_by_id"
    t.index ["client_id"], name: "index_bookings_on_client_id"
    t.index ["collection_assigned_to_id"], name: "index_bookings_on_collection_assigned_to_id"
    t.index ["collection_status"], name: "index_bookings_on_collection_status"
    t.index ["company_id"], name: "index_bookings_on_company_id"
    t.index ["converted_from_quote"], name: "index_bookings_on_converted_from_quote"
    t.index ["customer_email"], name: "index_bookings_on_customer_email"
    t.index ["days_past_due"], name: "index_bookings_on_days_past_due"
    t.index ["deleted"], name: "index_bookings_on_deleted"
    t.index ["delivery_start_date", "delivery_end_date"], name: "index_bookings_on_delivery_start_date_and_delivery_end_date"
    t.index ["instance_id", "status"], name: "index_bookings_on_instance_id_and_status"
    t.index ["instance_id"], name: "index_bookings_on_instance_id"
    t.index ["manager_id"], name: "index_bookings_on_manager_id"
    t.index ["payment_due_date"], name: "index_bookings_on_payment_due_date"
    t.index ["project_type_id"], name: "index_bookings_on_project_type_id"
    t.index ["quote_approved_by_id"], name: "index_bookings_on_quote_approved_by_id"
    t.index ["quote_expires_at"], name: "index_bookings_on_quote_expires_at"
    t.index ["quote_number"], name: "index_bookings_on_quote_number", unique: true
    t.index ["quote_status"], name: "index_bookings_on_quote_status"
    t.index ["recurring_booking_id"], name: "index_bookings_on_recurring_booking_id"
    t.index ["reference_number"], name: "index_bookings_on_reference_number", unique: true
    t.index ["refund_status"], name: "index_bookings_on_refund_status"
    t.index ["security_deposit_status"], name: "index_bookings_on_security_deposit_status"
    t.index ["start_date", "end_date"], name: "index_bookings_on_start_date_and_end_date"
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["venue_location_id"], name: "index_bookings_on_venue_location_id"
  end

  create_table "business_entities", force: :cascade do |t|
    t.boolean "active"
    t.bigint "client_id", null: false
    t.bigint "company_id"
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
    t.index ["company_id"], name: "index_business_entities_on_company_id"
    t.index ["instance_id"], name: "index_business_entities_on_instance_id"
  end

  create_table "client_communications", force: :cascade do |t|
    t.string "attachment"
    t.bigint "client_id", null: false
    t.datetime "communicated_at"
    t.integer "communication_type"
    t.bigint "company_id"
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.integer "direction"
    t.text "notes"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["client_id"], name: "index_client_communications_on_client_id"
    t.index ["company_id"], name: "index_client_communications_on_company_id"
    t.index ["contact_id"], name: "index_client_communications_on_contact_id"
    t.index ["user_id"], name: "index_client_communications_on_user_id"
  end

  create_table "client_metrics", force: :cascade do |t|
    t.decimal "average_rental_duration"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.integer "items_rented"
    t.date "metric_date"
    t.integer "rentals_count"
    t.integer "revenue_cents"
    t.string "revenue_currency"
    t.datetime "updated_at", null: false
    t.decimal "utilization_rate"
    t.index ["client_id"], name: "index_client_metrics_on_client_id"
  end

  create_table "client_surveys", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "client_id", null: false
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.text "feedback"
    t.integer "nps_score"
    t.integer "response_time_hours"
    t.integer "satisfaction_score"
    t.datetime "survey_completed_at"
    t.datetime "survey_sent_at"
    t.integer "survey_type"
    t.datetime "updated_at", null: false
    t.boolean "would_recommend"
    t.index ["booking_id"], name: "index_client_surveys_on_booking_id"
    t.index ["client_id"], name: "index_client_surveys_on_client_id"
    t.index ["company_id"], name: "index_client_surveys_on_company_id"
  end

  create_table "client_taggings", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "client_tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "tagged_at"
    t.bigint "tagged_by_id"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_taggings_on_client_id"
    t.index ["client_tag_id"], name: "index_client_taggings_on_client_tag_id"
  end

  create_table "client_tags", force: :cascade do |t|
    t.boolean "active"
    t.string "color"
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_client_tags_on_company_id"
  end

  create_table "client_users", force: :cascade do |t|
    t.boolean "active"
    t.bigint "client_id", null: false
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email"
    t.string "encrypted_password"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "password_digest"
    t.datetime "password_reset_sent_at"
    t.string "password_reset_token"
    t.integer "sign_in_count"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_users_on_client_id"
    t.index ["contact_id"], name: "index_client_users_on_contact_id"
  end

  create_table "clients", force: :cascade do |t|
    t.bigint "account_manager_id"
    t.integer "account_value_cents"
    t.string "account_value_currency", default: "USD"
    t.text "address"
    t.date "approved_credit_date"
    t.boolean "archived", default: false, null: false
    t.integer "average_booking_value_cents"
    t.string "average_booking_value_currency"
    t.integer "churn_risk"
    t.bigint "company_id"
    t.string "company_size"
    t.datetime "created_at", null: false
    t.integer "credit_limit_cents"
    t.string "credit_limit_currency"
    t.text "credit_notes"
    t.integer "credit_status"
    t.jsonb "custom_fields"
    t.boolean "deleted", default: false, null: false
    t.decimal "deposit_percentage"
    t.string "email"
    t.string "facebook_url"
    t.date "first_rental_date"
    t.integer "health_score"
    t.string "industry"
    t.string "instagram_handle"
    t.bigint "instance_id"
    t.datetime "last_activity_at"
    t.date "last_rental_date"
    t.integer "lifetime_value_cents"
    t.string "lifetime_value_currency"
    t.string "linkedin_url"
    t.string "market_segment"
    t.string "name", null: false
    t.text "notes"
    t.integer "outstanding_balance_cents"
    t.string "outstanding_balance_currency"
    t.bigint "parent_client_id"
    t.string "payment_method"
    t.integer "payment_terms_days"
    t.string "phone"
    t.integer "position"
    t.integer "priority", default: 1
    t.integer "priority_level"
    t.boolean "requires_deposit"
    t.string "service_tier"
    t.integer "total_rentals"
    t.string "twitter_handle"
    t.datetime "updated_at", null: false
    t.string "website"
    t.string "website_url"
    t.index ["archived"], name: "index_clients_on_archived"
    t.index ["company_id"], name: "index_clients_on_company_id"
    t.index ["deleted"], name: "index_clients_on_deleted"
    t.index ["email"], name: "index_clients_on_email"
    t.index ["instance_id", "archived"], name: "index_clients_on_instance_id_and_archived"
    t.index ["instance_id"], name: "index_clients_on_instance_id"
  end

  create_table "collection_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.bigint "product_collection_id", null: false
    t.string "referrer"
    t.string "session_id"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id"
    t.datetime "viewed_at"
    t.index ["product_collection_id", "viewed_at"], name: "index_collection_views_on_product_collection_id_and_viewed_at"
    t.index ["product_collection_id"], name: "index_collection_views_on_product_collection_id"
    t.index ["session_id"], name: "index_collection_views_on_session_id"
    t.index ["user_id"], name: "index_collection_views_on_user_id"
    t.index ["viewed_at"], name: "index_collection_views_on_viewed_at"
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

  create_table "companies", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "address"
    t.string "business_email"
    t.string "business_phone"
    t.datetime "created_at", null: false
    t.string "custom_domain"
    t.string "default_currency", default: "USD"
    t.boolean "deleted", default: false, null: false
    t.datetime "deleted_at"
    t.string "logo"
    t.string "name", null: false
    t.string "primary_color", default: "#3B82F6"
    t.string "secondary_color", default: "#10B981"
    t.jsonb "settings", default: {}
    t.integer "status", default: 0, null: false
    t.string "subdomain", null: false
    t.datetime "subscription_cancelled_at"
    t.datetime "subscription_started_at"
    t.integer "subscription_tier", default: 0
    t.string "timezone", default: "UTC"
    t.datetime "trial_ends_at"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_companies_on_active"
    t.index ["custom_domain"], name: "index_companies_on_custom_domain", unique: true, where: "(custom_domain IS NOT NULL)"
    t.index ["deleted"], name: "index_companies_on_deleted"
    t.index ["status"], name: "index_companies_on_status"
    t.index ["subdomain"], name: "index_companies_on_subdomain", unique: true
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.boolean "decision_maker"
    t.string "email"
    t.string "first_name"
    t.boolean "is_primary"
    t.string "last_name"
    t.string "mobile"
    t.text "notes"
    t.string "phone"
    t.boolean "receives_invoices"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_contacts_on_client_id"
    t.index ["company_id"], name: "index_contacts_on_company_id"
  end

  create_table "contract_signatures", force: :cascade do |t|
    t.boolean "accepted_terms", default: false
    t.bigint "contract_id", null: false
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.string "ip_address"
    t.text "signature_data"
    t.integer "signature_type", default: 0, null: false
    t.datetime "signed_at"
    t.string "signer_email", null: false
    t.string "signer_name", null: false
    t.integer "signer_role", default: 0, null: false
    t.string "terms_version"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id"
    t.string "witness_name"
    t.text "witness_signature"
    t.index ["accepted_terms"], name: "index_contract_signatures_on_accepted_terms"
    t.index ["contract_id", "signer_role"], name: "index_contract_signatures_on_contract_and_role"
    t.index ["contract_id"], name: "index_contract_signatures_on_contract_id"
    t.index ["deleted"], name: "index_contract_signatures_on_deleted"
    t.index ["signature_type"], name: "index_contract_signatures_on_signature_type"
    t.index ["signed_at"], name: "index_contract_signatures_on_signed_at"
    t.index ["signer_email"], name: "index_contract_signatures_on_signer_email"
    t.index ["signer_role"], name: "index_contract_signatures_on_signer_role"
    t.index ["user_id"], name: "index_contract_signatures_on_user_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.bigint "booking_id"
    t.bigint "company_id"
    t.text "content"
    t.integer "contract_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.date "effective_date"
    t.date "expiry_date"
    t.string "pdf_file"
    t.boolean "requires_signature", default: true
    t.integer "status", default: 0, null: false
    t.boolean "template", default: false
    t.string "template_name"
    t.string "terms_url"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.jsonb "variables", default: {}
    t.string "version", default: "1.0"
    t.index ["booking_id"], name: "index_contracts_on_booking_id"
    t.index ["company_id"], name: "index_contracts_on_company_id"
    t.index ["contract_type"], name: "index_contracts_on_contract_type"
    t.index ["deleted"], name: "index_contracts_on_deleted"
    t.index ["effective_date"], name: "index_contracts_on_effective_date"
    t.index ["status"], name: "index_contracts_on_status"
    t.index ["template"], name: "index_contracts_on_template"
    t.index ["template_name"], name: "index_contracts_on_template_name"
  end

  create_table "damage_reports", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "product_id", null: false
    t.integer "repair_cost_cents"
    t.string "repair_cost_currency"
    t.bigint "reported_by_id", null: false
    t.text "resolution_notes"
    t.boolean "resolved", default: false
    t.datetime "resolved_at"
    t.integer "severity", default: 0
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_damage_reports_on_booking_id"
    t.index ["company_id"], name: "index_damage_reports_on_company_id"
    t.index ["product_id"], name: "index_damage_reports_on_product_id"
    t.index ["reported_by_id"], name: "index_damage_reports_on_reported_by_id"
    t.index ["resolved"], name: "index_damage_reports_on_resolved"
    t.index ["severity"], name: "index_damage_reports_on_severity"
  end

  create_table "email_queues", force: :cascade do |t|
    t.integer "attempts"
    t.text "body"
    t.bigint "company_id"
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
    t.index ["company_id"], name: "index_email_queues_on_company_id"
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

  create_table "insurance_certificates", force: :cascade do |t|
    t.string "certificate_file"
    t.bigint "company_id"
    t.integer "coverage_amount_cents"
    t.string "coverage_amount_currency"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.date "end_date"
    t.text "notes"
    t.string "policy_number"
    t.bigint "product_id", null: false
    t.string "provider"
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_insurance_certificates_on_company_id"
    t.index ["product_id"], name: "index_insurance_certificates_on_product_id"
  end

  create_table "invitation_codes", force: :cascade do |t|
    t.string "code"
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.integer "current_uses"
    t.boolean "deleted"
    t.datetime "expires_at"
    t.bigint "instance_id", null: false
    t.integer "max_uses"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_invitation_codes_on_company_id"
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
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.integer "daily_price_cents", default: 0, null: false
    t.string "daily_price_currency", default: "USD", null: false
    t.text "description"
    t.bigint "instance_id"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_kits_on_active"
    t.index ["company_id"], name: "index_kits_on_company_id"
    t.index ["instance_id"], name: "index_kits_on_instance_id"
  end

  create_table "leads", force: :cascade do |t|
    t.bigint "assigned_to_id"
    t.string "company"
    t.bigint "company_id"
    t.datetime "converted_at"
    t.bigint "converted_to_client_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.date "expected_close_date"
    t.integer "expected_value_cents"
    t.string "expected_value_currency"
    t.text "lost_reason"
    t.string "name"
    t.text "notes"
    t.string "phone"
    t.integer "probability"
    t.string "source"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_leads_on_company_id"
  end

  create_table "location_histories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "location_id", null: false
    t.datetime "moved_at", default: -> { "CURRENT_TIMESTAMP" }
    t.bigint "moved_by_id"
    t.text "notes"
    t.bigint "previous_location_id"
    t.bigint "trackable_id", null: false
    t.string "trackable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_location_histories_on_location_id"
    t.index ["moved_by_id"], name: "index_location_histories_on_moved_by_id"
    t.index ["previous_location_id"], name: "index_location_histories_on_previous_location_id"
    t.index ["trackable_type", "trackable_id", "moved_at"], name: "idx_on_trackable_type_trackable_id_moved_at_d47bca002c"
    t.index ["trackable_type", "trackable_id"], name: "index_location_histories_on_trackable"
  end

  create_table "location_transfers", force: :cascade do |t|
    t.bigint "booking_id"
    t.bigint "booking_line_item_id"
    t.string "carrier"
    t.bigint "company_id"
    t.datetime "completed_at"
    t.bigint "completed_by_id"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.datetime "expected_arrival_at"
    t.bigint "from_location_id", null: false
    t.datetime "in_transit_at"
    t.datetime "initiated_at"
    t.bigint "initiated_by_id"
    t.text "notes"
    t.integer "status", default: 0, null: false
    t.bigint "to_location_id", null: false
    t.string "tracking_number"
    t.integer "transfer_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_location_transfers_on_booking_id"
    t.index ["booking_line_item_id"], name: "index_location_transfers_on_booking_line_item_id"
    t.index ["company_id"], name: "index_location_transfers_on_company_id"
    t.index ["completed_by_id"], name: "index_location_transfers_on_completed_by_id"
    t.index ["deleted"], name: "index_location_transfers_on_deleted"
    t.index ["from_location_id", "status"], name: "index_location_transfers_on_from_location_id_and_status"
    t.index ["from_location_id"], name: "index_location_transfers_on_from_location_id"
    t.index ["initiated_by_id"], name: "index_location_transfers_on_initiated_by_id"
    t.index ["status"], name: "index_location_transfers_on_status"
    t.index ["to_location_id", "status"], name: "index_location_transfers_on_to_location_id_and_status"
    t.index ["to_location_id"], name: "index_location_transfers_on_to_location_id"
    t.index ["transfer_type"], name: "index_location_transfers_on_transfer_type"
  end

  create_table "locations", force: :cascade do |t|
    t.text "address"
    t.boolean "archived", default: false, null: false
    t.string "barcode"
    t.bigint "client_id"
    t.bigint "company_id"
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
    t.index ["company_id"], name: "index_locations_on_company_id"
    t.index ["deleted"], name: "index_locations_on_deleted"
    t.index ["instance_id"], name: "index_locations_on_instance_id"
    t.index ["parent_id"], name: "index_locations_on_parent_id"
  end

  create_table "maintenance_jobs", force: :cascade do |t|
    t.bigint "assigned_to_id"
    t.bigint "company_id"
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
    t.index ["company_id"], name: "index_maintenance_jobs_on_company_id"
    t.index ["instance_id"], name: "index_maintenance_jobs_on_instance_id"
    t.index ["product_id"], name: "index_maintenance_jobs_on_product_id"
  end

  create_table "manufacturers", force: :cascade do |t|
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.bigint "instance_id"
    t.string "name", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["company_id"], name: "index_manufacturers_on_company_id"
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

  create_table "payment_plans", force: :cascade do |t|
    t.boolean "active"
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "down_payment_cents"
    t.string "down_payment_currency"
    t.integer "installment_amount_cents"
    t.string "installment_amount_currency"
    t.integer "installment_frequency"
    t.integer "installments_paid"
    t.string "name"
    t.date "next_payment_date"
    t.text "notes"
    t.integer "number_of_installments"
    t.string "payment_method"
    t.date "start_date"
    t.integer "status"
    t.integer "total_amount_cents"
    t.string "total_amount_currency"
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_payment_plans_on_booking_id"
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
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.bigint "instance_id", null: false
    t.string "name"
    t.jsonb "permissions"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_permission_groups_on_company_id"
    t.index ["instance_id"], name: "index_permission_groups_on_instance_id"
  end

  create_table "positions", force: :cascade do |t|
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.text "description"
    t.bigint "instance_id", null: false
    t.string "name"
    t.integer "rank"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_positions_on_company_id"
    t.index ["instance_id"], name: "index_positions_on_instance_id"
  end

  create_table "pricing_rules", force: :cascade do |t|
    t.boolean "active"
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.integer "day_of_week"
    t.boolean "deleted"
    t.decimal "discount_percentage"
    t.date "end_date"
    t.integer "max_days"
    t.integer "min_days"
    t.string "name"
    t.integer "price_override_cents"
    t.string "price_override_currency"
    t.integer "priority"
    t.bigint "product_id", null: false
    t.bigint "product_type_id", null: false
    t.integer "rule_type"
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_pricing_rules_on_company_id"
    t.index ["product_id"], name: "index_pricing_rules_on_product_id"
    t.index ["product_type_id"], name: "index_pricing_rules_on_product_type_id"
  end

  create_table "product_accessories", force: :cascade do |t|
    t.bigint "accessory_id", null: false
    t.integer "accessory_type", default: 0
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.integer "default_quantity", default: 1
    t.bigint "product_id", null: false
    t.boolean "required", default: false
    t.datetime "updated_at", null: false
    t.index ["accessory_id"], name: "index_product_accessories_on_accessory_id"
    t.index ["company_id"], name: "index_product_accessories_on_company_id"
    t.index ["product_id", "accessory_id"], name: "index_product_accessories_on_product_id_and_accessory_id", unique: true
    t.index ["product_id"], name: "index_product_accessories_on_product_id"
  end

  create_table "product_asset_flags", force: :cascade do |t|
    t.bigint "asset_flag_id", null: false
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_flag_id"], name: "index_product_asset_flags_on_asset_flag_id"
    t.index ["product_id"], name: "index_product_asset_flags_on_product_id"
  end

  create_table "product_bundle_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0
    t.bigint "product_bundle_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1
    t.boolean "required", default: true
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_product_bundle_items_on_position"
    t.index ["product_bundle_id", "product_id"], name: "index_product_bundle_items_on_product_bundle_id_and_product_id", unique: true
    t.index ["product_bundle_id"], name: "index_product_bundle_items_on_product_bundle_id"
    t.index ["product_id"], name: "index_product_bundle_items_on_product_id"
  end

  create_table "product_bundles", force: :cascade do |t|
    t.boolean "active", default: true
    t.integer "bundle_type", default: 0
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.text "description"
    t.decimal "discount_percentage", precision: 5, scale: 2
    t.boolean "enforce_bundling", default: false
    t.bigint "instance_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_product_bundles_on_active"
    t.index ["bundle_type"], name: "index_product_bundles_on_bundle_type"
    t.index ["company_id"], name: "index_product_bundles_on_company_id"
    t.index ["instance_id"], name: "index_product_bundles_on_instance_id"
  end

  create_table "product_collection_items", force: :cascade do |t|
    t.datetime "added_at"
    t.bigint "added_by_id"
    t.datetime "created_at", null: false
    t.boolean "featured"
    t.text "notes"
    t.integer "position"
    t.bigint "product_collection_id", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["added_by_id"], name: "index_product_collection_items_on_added_by_id"
    t.index ["product_collection_id"], name: "index_product_collection_items_on_product_collection_id"
    t.index ["product_id"], name: "index_product_collection_items_on_product_id"
  end

  create_table "product_collections", force: :cascade do |t|
    t.boolean "active"
    t.integer "collection_type"
    t.string "color"
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "display_template"
    t.date "end_date"
    t.boolean "featured"
    t.string "icon"
    t.boolean "is_dynamic"
    t.text "meta_description"
    t.string "meta_title"
    t.string "name"
    t.bigint "parent_collection_id"
    t.integer "position"
    t.integer "product_count"
    t.jsonb "rules"
    t.string "short_description"
    t.string "slug"
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.integer "visibility"
    t.index ["company_id"], name: "index_product_collections_on_company_id"
    t.index ["slug"], name: "index_product_collections_on_slug", unique: true
  end

  create_table "product_instances", force: :cascade do |t|
    t.string "asset_tag"
    t.bigint "company_id"
    t.integer "condition", default: 0
    t.datetime "created_at", null: false
    t.bigint "current_location_id"
    t.boolean "deleted", default: false
    t.text "notes"
    t.bigint "product_id", null: false
    t.date "purchase_date"
    t.integer "purchase_price_cents"
    t.string "purchase_price_currency"
    t.string "serial_number"
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["asset_tag"], name: "index_product_instances_on_asset_tag", unique: true
    t.index ["company_id"], name: "index_product_instances_on_company_id"
    t.index ["current_location_id"], name: "index_product_instances_on_current_location_id"
    t.index ["product_id"], name: "index_product_instances_on_product_id"
    t.index ["serial_number"], name: "index_product_instances_on_serial_number", unique: true
  end

  create_table "product_metrics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "idle_days"
    t.date "metric_date"
    t.bigint "product_id", null: false
    t.integer "rental_days"
    t.integer "revenue_cents"
    t.string "revenue_currency"
    t.integer "times_rented"
    t.datetime "updated_at", null: false
    t.decimal "utilization_rate"
    t.index ["product_id"], name: "index_product_metrics_on_product_id"
  end

  create_table "product_types", force: :cascade do |t|
    t.boolean "archived", default: false
    t.string "category"
    t.string "color"
    t.bigint "company_id"
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
    t.index ["company_id"], name: "index_product_types_on_company_id"
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
    t.bigint "company_id"
    t.integer "condition", default: 0
    t.text "condition_notes"
    t.datetime "created_at", null: false
    t.integer "current_value_cents"
    t.string "current_value_currency"
    t.jsonb "custom_fields", default: {}
    t.integer "daily_price_cents", default: 0, null: false
    t.string "daily_price_currency", default: "USD", null: false
    t.boolean "damage_waiver_available"
    t.integer "damage_waiver_price_cents"
    t.string "damage_waiver_price_currency"
    t.boolean "deleted", default: false, null: false
    t.decimal "depreciation_rate"
    t.text "description"
    t.datetime "end_date"
    t.boolean "featured", default: false
    t.boolean "in_maintenance", default: false
    t.boolean "in_transit", default: false
    t.bigint "instance_id"
    t.date "insurance_expiry"
    t.string "insurance_policy_number"
    t.boolean "insurance_required"
    t.date "last_condition_check"
    t.date "last_depreciation_date"
    t.integer "late_fee_cents"
    t.string "late_fee_currency"
    t.integer "late_fee_type"
    t.decimal "mass", precision: 10, scale: 2
    t.integer "minimum_rental_days"
    t.string "model_number"
    t.string "name", null: false
    t.boolean "out_of_service", default: false
    t.integer "popularity_score", default: 0
    t.bigint "product_type_id"
    t.date "purchase_date"
    t.integer "purchase_price_cents"
    t.string "purchase_price_currency"
    t.integer "quantity", default: 1, null: false
    t.integer "replacement_cost_cents"
    t.string "replacement_cost_currency"
    t.datetime "reserved_until"
    t.string "serial_numbers", default: [], array: true
    t.boolean "show_public", default: true, null: false
    t.jsonb "specifications", default: {}
    t.bigint "storage_location_id"
    t.string "tags", default: [], array: true
    t.text "transit_notes"
    t.datetime "updated_at", null: false
    t.integer "value_cents", default: 0, null: false
    t.integer "weekend_price_cents"
    t.string "weekend_price_currency"
    t.integer "weekly_price_cents", default: 0, null: false
    t.string "weekly_price_currency", default: "USD", null: false
    t.integer "workflow_state", default: 0
    t.index ["active"], name: "index_products_on_active"
    t.index ["archived"], name: "index_products_on_archived"
    t.index ["asset_tag"], name: "index_products_on_asset_tag", unique: true, where: "(asset_tag IS NOT NULL)"
    t.index ["barcode"], name: "index_products_on_barcode", unique: true, where: "(barcode IS NOT NULL)"
    t.index ["category"], name: "index_products_on_category"
    t.index ["company_id"], name: "index_products_on_company_id"
    t.index ["custom_fields"], name: "index_products_on_custom_fields", using: :gin
    t.index ["deleted"], name: "index_products_on_deleted"
    t.index ["featured"], name: "index_products_on_featured"
    t.index ["instance_id", "active"], name: "index_products_on_instance_id_and_active"
    t.index ["instance_id"], name: "index_products_on_instance_id"
    t.index ["model_number"], name: "index_products_on_model_number"
    t.index ["popularity_score"], name: "index_products_on_popularity_score"
    t.index ["product_type_id"], name: "index_products_on_product_type_id"
    t.index ["specifications"], name: "index_products_on_specifications", using: :gin
    t.index ["storage_location_id"], name: "index_products_on_storage_location_id"
    t.index ["tags"], name: "index_products_on_tags", using: :gin
  end

  create_table "project_types", force: :cascade do |t|
    t.boolean "active"
    t.boolean "auto_confirm"
    t.bigint "company_id"
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
    t.index ["company_id"], name: "index_project_types_on_company_id"
    t.index ["instance_id"], name: "index_project_types_on_instance_id"
  end

  create_table "recurring_bookings", force: :cascade do |t|
    t.boolean "active", default: true
    t.jsonb "booking_template", default: {}
    t.bigint "client_id"
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.integer "day_of_month"
    t.integer "day_of_week"
    t.boolean "deleted", default: false
    t.datetime "end_date"
    t.integer "frequency", default: 0, null: false
    t.integer "interval", default: 1
    t.datetime "last_generated"
    t.integer "max_occurrences"
    t.string "name", null: false
    t.datetime "next_occurrence", null: false
    t.integer "occurrence_count", default: 0
    t.datetime "start_date", null: false
    t.string "subscription_type"
    t.datetime "updated_at", null: false
    t.index ["active", "next_occurrence"], name: "index_recurring_bookings_on_active_and_next_occurrence"
    t.index ["active"], name: "index_recurring_bookings_on_active"
    t.index ["client_id"], name: "index_recurring_bookings_on_client_id"
    t.index ["company_id"], name: "index_recurring_bookings_on_company_id"
    t.index ["created_by_id"], name: "index_recurring_bookings_on_created_by_id"
    t.index ["deleted"], name: "index_recurring_bookings_on_deleted"
    t.index ["frequency"], name: "index_recurring_bookings_on_frequency"
    t.index ["next_occurrence"], name: "index_recurring_bookings_on_next_occurrence"
  end

  create_table "sales_tasks", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "company_id"
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
    t.index ["company_id"], name: "index_sales_tasks_on_company_id"
    t.index ["instance_id"], name: "index_sales_tasks_on_instance_id"
    t.index ["user_id"], name: "index_sales_tasks_on_user_id"
  end

  create_table "service_agreements", force: :cascade do |t|
    t.boolean "active"
    t.integer "agreement_type"
    t.boolean "auto_renew"
    t.bigint "client_id", null: false
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.decimal "discount_percentage"
    t.date "end_date"
    t.integer "minimum_commitment_cents"
    t.string "minimum_commitment_currency"
    t.string "name"
    t.text "notes"
    t.integer "payment_schedule"
    t.integer "renewal_type"
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_service_agreements_on_client_id"
    t.index ["company_id"], name: "index_service_agreements_on_company_id"
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
    t.bigint "company_id"
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
    t.index ["company_id"], name: "index_staff_roles_on_company_id"
    t.index ["instance_id"], name: "index_staff_roles_on_instance_id"
  end

  create_table "tax_rates", force: :cascade do |t|
    t.boolean "active"
    t.boolean "applies_to_deposits"
    t.boolean "applies_to_shipping"
    t.integer "calculation_method"
    t.string "city"
    t.bigint "company_id"
    t.boolean "compound"
    t.string "country"
    t.datetime "created_at", null: false
    t.date "end_date"
    t.integer "maximum_amount_cents"
    t.integer "minimum_amount_cents"
    t.string "name"
    t.integer "position"
    t.decimal "rate"
    t.integer "rate_cents"
    t.date "start_date"
    t.string "state"
    t.string "tax_code"
    t.integer "tax_type"
    t.datetime "updated_at", null: false
    t.string "zip_code_pattern"
    t.index ["company_id"], name: "index_tax_rates_on_company_id"
    t.index ["tax_code"], name: "index_tax_rates_on_tax_code", unique: true
  end

  create_table "user_certifications", force: :cascade do |t|
    t.string "certificate_number"
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.date "expiry_date"
    t.date "issued_date"
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["company_id"], name: "index_user_certifications_on_company_id"
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
    t.bigint "company_id"
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
    t.index ["company_id"], name: "index_users_on_company_id"
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
  add_foreign_key "addresses", "companies"
  add_foreign_key "asset_assignments", "companies"
  add_foreign_key "asset_assignments", "instances"
  add_foreign_key "asset_assignments", "products"
  add_foreign_key "asset_flags", "companies"
  add_foreign_key "asset_flags", "instances"
  add_foreign_key "asset_group_products", "asset_groups"
  add_foreign_key "asset_group_products", "products"
  add_foreign_key "asset_group_watchers", "asset_groups"
  add_foreign_key "asset_group_watchers", "users"
  add_foreign_key "asset_groups", "companies"
  add_foreign_key "asset_groups", "instances"
  add_foreign_key "asset_logs", "companies"
  add_foreign_key "asset_logs", "products"
  add_foreign_key "asset_logs", "users"
  add_foreign_key "booking_comments", "bookings"
  add_foreign_key "booking_comments", "users"
  add_foreign_key "booking_line_item_instances", "booking_line_items"
  add_foreign_key "booking_line_item_instances", "product_instances"
  add_foreign_key "booking_line_items", "bookings"
  add_foreign_key "booking_line_items", "location_transfers"
  add_foreign_key "booking_line_items", "locations", column: "delivery_location_id"
  add_foreign_key "booking_line_items", "locations", column: "fulfillment_location_id"
  add_foreign_key "booking_line_items", "locations", column: "pickup_location_id"
  add_foreign_key "booking_line_items", "users", column: "delivered_by_id"
  add_foreign_key "booking_templates", "clients"
  add_foreign_key "booking_templates", "companies"
  add_foreign_key "booking_templates", "users", column: "created_by_id"
  add_foreign_key "bookings", "clients"
  add_foreign_key "bookings", "companies"
  add_foreign_key "bookings", "instances"
  add_foreign_key "bookings", "locations", column: "venue_location_id"
  add_foreign_key "bookings", "project_types"
  add_foreign_key "bookings", "recurring_bookings"
  add_foreign_key "bookings", "users", column: "cancelled_by_id", on_delete: :nullify
  add_foreign_key "bookings", "users", column: "manager_id"
  add_foreign_key "bookings", "users", column: "quote_approved_by_id", on_delete: :nullify
  add_foreign_key "business_entities", "clients"
  add_foreign_key "business_entities", "companies"
  add_foreign_key "business_entities", "instances"
  add_foreign_key "client_communications", "clients"
  add_foreign_key "client_communications", "companies"
  add_foreign_key "client_communications", "contacts"
  add_foreign_key "client_communications", "users"
  add_foreign_key "client_metrics", "clients"
  add_foreign_key "client_surveys", "bookings"
  add_foreign_key "client_surveys", "clients"
  add_foreign_key "client_surveys", "companies"
  add_foreign_key "client_taggings", "client_tags"
  add_foreign_key "client_taggings", "clients"
  add_foreign_key "client_tags", "companies"
  add_foreign_key "client_users", "clients"
  add_foreign_key "client_users", "contacts"
  add_foreign_key "clients", "companies"
  add_foreign_key "clients", "instances"
  add_foreign_key "collection_views", "product_collections"
  add_foreign_key "collection_views", "users"
  add_foreign_key "comment_upvotes", "comments"
  add_foreign_key "comment_upvotes", "users"
  add_foreign_key "comments", "comments", column: "parent_comment_id"
  add_foreign_key "comments", "instances"
  add_foreign_key "comments", "users"
  add_foreign_key "contacts", "clients"
  add_foreign_key "contacts", "companies"
  add_foreign_key "contract_signatures", "contracts"
  add_foreign_key "contract_signatures", "users"
  add_foreign_key "contracts", "bookings"
  add_foreign_key "contracts", "companies"
  add_foreign_key "damage_reports", "bookings"
  add_foreign_key "damage_reports", "companies"
  add_foreign_key "damage_reports", "products"
  add_foreign_key "damage_reports", "users", column: "reported_by_id"
  add_foreign_key "email_queues", "companies"
  add_foreign_key "email_queues", "instances"
  add_foreign_key "instances", "users", column: "owner_id"
  add_foreign_key "insurance_certificates", "companies"
  add_foreign_key "insurance_certificates", "products"
  add_foreign_key "invitation_codes", "companies"
  add_foreign_key "invitation_codes", "instances"
  add_foreign_key "invitation_codes", "users", column: "created_by_id"
  add_foreign_key "kit_items", "kits"
  add_foreign_key "kit_items", "products"
  add_foreign_key "kits", "companies"
  add_foreign_key "kits", "instances"
  add_foreign_key "leads", "companies"
  add_foreign_key "location_histories", "locations"
  add_foreign_key "location_histories", "locations", column: "previous_location_id"
  add_foreign_key "location_histories", "users", column: "moved_by_id"
  add_foreign_key "location_transfers", "booking_line_items"
  add_foreign_key "location_transfers", "bookings"
  add_foreign_key "location_transfers", "companies"
  add_foreign_key "location_transfers", "locations", column: "from_location_id"
  add_foreign_key "location_transfers", "locations", column: "to_location_id"
  add_foreign_key "location_transfers", "users", column: "completed_by_id"
  add_foreign_key "location_transfers", "users", column: "initiated_by_id"
  add_foreign_key "locations", "clients"
  add_foreign_key "locations", "companies"
  add_foreign_key "locations", "instances"
  add_foreign_key "locations", "locations", column: "parent_id"
  add_foreign_key "maintenance_jobs", "companies"
  add_foreign_key "maintenance_jobs", "instances"
  add_foreign_key "maintenance_jobs", "products"
  add_foreign_key "maintenance_jobs", "users", column: "assigned_to_id"
  add_foreign_key "manufacturers", "companies"
  add_foreign_key "manufacturers", "instances"
  add_foreign_key "notes", "users"
  add_foreign_key "payment_plans", "bookings"
  add_foreign_key "payments", "bookings"
  add_foreign_key "payments", "instances"
  add_foreign_key "permission_groups", "companies"
  add_foreign_key "permission_groups", "instances"
  add_foreign_key "positions", "companies"
  add_foreign_key "positions", "instances"
  add_foreign_key "pricing_rules", "companies"
  add_foreign_key "pricing_rules", "product_types"
  add_foreign_key "pricing_rules", "products"
  add_foreign_key "product_accessories", "companies"
  add_foreign_key "product_accessories", "products"
  add_foreign_key "product_accessories", "products", column: "accessory_id"
  add_foreign_key "product_asset_flags", "asset_flags"
  add_foreign_key "product_asset_flags", "products"
  add_foreign_key "product_bundle_items", "product_bundles"
  add_foreign_key "product_bundle_items", "products"
  add_foreign_key "product_bundles", "companies"
  add_foreign_key "product_bundles", "instances"
  add_foreign_key "product_collection_items", "product_collections"
  add_foreign_key "product_collection_items", "products"
  add_foreign_key "product_collection_items", "users", column: "added_by_id"
  add_foreign_key "product_collections", "companies"
  add_foreign_key "product_instances", "companies"
  add_foreign_key "product_instances", "locations", column: "current_location_id"
  add_foreign_key "product_instances", "products"
  add_foreign_key "product_metrics", "products"
  add_foreign_key "product_types", "companies"
  add_foreign_key "product_types", "instances"
  add_foreign_key "product_types", "manufacturers"
  add_foreign_key "products", "companies"
  add_foreign_key "products", "instances"
  add_foreign_key "products", "locations", column: "storage_location_id"
  add_foreign_key "products", "product_types"
  add_foreign_key "project_types", "companies"
  add_foreign_key "project_types", "instances"
  add_foreign_key "recurring_bookings", "clients"
  add_foreign_key "recurring_bookings", "companies"
  add_foreign_key "recurring_bookings", "users", column: "created_by_id"
  add_foreign_key "sales_tasks", "clients"
  add_foreign_key "sales_tasks", "companies"
  add_foreign_key "sales_tasks", "instances"
  add_foreign_key "sales_tasks", "users"
  add_foreign_key "service_agreements", "clients"
  add_foreign_key "service_agreements", "companies"
  add_foreign_key "staff_applications", "staff_roles"
  add_foreign_key "staff_applications", "users"
  add_foreign_key "staff_applications", "users", column: "reviewer_id"
  add_foreign_key "staff_assignments", "bookings"
  add_foreign_key "staff_assignments", "staff_roles"
  add_foreign_key "staff_assignments", "users"
  add_foreign_key "staff_roles", "bookings"
  add_foreign_key "staff_roles", "companies"
  add_foreign_key "staff_roles", "instances"
  add_foreign_key "tax_rates", "companies"
  add_foreign_key "user_certifications", "companies"
  add_foreign_key "user_certifications", "users"
  add_foreign_key "user_positions", "instances"
  add_foreign_key "user_positions", "positions"
  add_foreign_key "user_positions", "users"
  add_foreign_key "user_preferences", "users"
  add_foreign_key "users", "companies"
  add_foreign_key "users", "instances"
  add_foreign_key "users", "permission_groups"
  add_foreign_key "waitlist_entries", "instances"
end
