ActiveRecord::Schema[7.1].define(version: 2026_02_01_000001) do
  enable_extension "plpgsql"

  create_table "properties", force: :cascade do |t|
    t.string "name", null: false
    t.string "address", null: false
    t.string "city", null: false
    t.string "property_type", default: "residential"
    t.integer "units_count", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_properties_on_city"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone"
    t.bigint "property_id", null: false
    t.string "unit_number"
    t.date "lease_start"
    t.date "lease_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_tenants_on_property_id"
    t.index ["email"], name: "index_tenants_on_email", unique: true
  end

  create_table "work_orders", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "open"
    t.string "priority", default: "normal"
    t.bigint "property_id", null: false
    t.bigint "tenant_id"
    t.bigint "assigned_to_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_work_orders_on_property_id"
    t.index ["status"], name: "index_work_orders_on_status"
    t.index ["priority"], name: "index_work_orders_on_priority"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "role", default: "manager"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "tenants", "properties"
  add_foreign_key "work_orders", "properties"
  add_foreign_key "work_orders", "tenants"
  add_foreign_key "work_orders", "users", column: "assigned_to_id"
end
