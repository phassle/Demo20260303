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

ActiveRecord::Schema[7.1].define(version: 2026_03_02_000001) do
  # These are extensions that must be enabled in order to support this database
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
    t.index ["email"], name: "index_tenants_on_email", unique: true
    t.index ["property_id"], name: "index_tenants_on_property_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "role", default: "manager"
    t.string "api_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
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
    t.index ["priority"], name: "index_work_orders_on_priority"
    t.index ["property_id"], name: "index_work_orders_on_property_id"
    t.index ["status"], name: "index_work_orders_on_status"
  end

  add_foreign_key "tenants", "properties"
  add_foreign_key "work_orders", "properties"
  add_foreign_key "work_orders", "tenants"
  add_foreign_key "work_orders", "users", column: "assigned_to_id"
end
