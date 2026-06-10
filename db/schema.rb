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

ActiveRecord::Schema[8.1].define(version: 2026_06_10_182822) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ledger_entries", force: :cascade do |t|
    t.decimal "amount", precision: 28, scale: 8, null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "reference_id"
    t.string "transaction_type", null: false
    t.bigint "wallet_id", null: false
    t.index ["wallet_id"], name: "index_ledger_entries_on_wallet_id"
  end

  create_table "orders", force: :cascade do |t|
    t.uuid "client_order_id", null: false
    t.datetime "created_at", null: false
    t.decimal "filled_quantity", precision: 28, scale: 8, default: "0.0", null: false
    t.integer "leverage", default: 1, null: false
    t.string "order_type", null: false
    t.string "position_effect", null: false
    t.decimal "price", precision: 28, scale: 8
    t.decimal "quantity", precision: 28, scale: 8, null: false
    t.string "side", null: false
    t.string "status", null: false
    t.string "symbol", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["client_order_id"], name: "index_orders_on_client_order_id", unique: true
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "positions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "entry_price", precision: 28, scale: 8, null: false
    t.integer "leverage", default: 1, null: false
    t.decimal "liquidation_price", precision: 28, scale: 8, null: false
    t.decimal "maintenance_margin", precision: 28, scale: 8, null: false
    t.string "side", null: false
    t.decimal "size", precision: 28, scale: 8, null: false
    t.string "status", null: false
    t.string "symbol", null: false
    t.decimal "unrealized_pnl", precision: 28, scale: 8, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_positions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "wallets", force: :cascade do |t|
    t.decimal "available_balance", precision: 28, scale: 8, default: "0.0", null: false
    t.string "balance_type", null: false
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.decimal "locked_balance", precision: 28, scale: 8, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "currency", "balance_type"], name: "unique_user_currency_type", unique: true
    t.index ["user_id"], name: "index_wallets_on_user_id"
  end

  add_foreign_key "ledger_entries", "wallets"
  add_foreign_key "orders", "users"
  add_foreign_key "positions", "users"
  add_foreign_key "wallets", "users"
end
