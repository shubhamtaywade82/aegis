class CreateAutonomousTradingTables < ActiveRecord::Migration[8.1]
  def change
    # 1. Users
    create_table :users do |t|
      t.string :email, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true

    # 2. Wallets (Spot & Futures balance partitions)
    create_table :wallets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :currency, null: false
      t.string :balance_type, null: false
      t.decimal :available_balance, precision: 28, scale: 8, null: false, default: 0.0
      t.decimal :locked_balance, precision: 28, scale: 8, null: false, default: 0.0
      t.timestamps
    end
    add_index :wallets, [ :user_id, :currency, :balance_type ], unique: true, name: 'unique_user_currency_type'

    # 3. Double-entry immutable Ledger Entries
    create_table :ledger_entries do |t|
      t.references :wallet, null: false, foreign_key: true
      t.decimal :amount, precision: 28, scale: 8, null: false
      t.string :transaction_type, null: false
      t.string :reference_id
      t.timestamp :created_at, null: false
    end

    # 4. Local Orders table
    create_table :orders do |t|
      t.uuid :client_order_id, null: false
      t.references :user, null: false, foreign_key: true
      t.string :symbol, null: false
      t.string :side, null: false
      t.string :order_type, null: false
      t.string :position_effect, null: false
      t.decimal :price, precision: 28, scale: 8
      t.decimal :quantity, precision: 28, scale: 8, null: false
      t.decimal :filled_quantity, precision: 28, scale: 8, null: false, default: 0.0
      t.string :status, null: false
      t.integer :leverage, null: false, default: 1
      t.timestamps
    end
    add_index :orders, :client_order_id, unique: true

    # 5. Local Positions table
    create_table :positions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :symbol, null: false
      t.string :side, null: false
      t.integer :leverage, null: false, default: 1
      t.decimal :size, precision: 28, scale: 8, null: false
      t.decimal :entry_price, precision: 28, scale: 8, null: false
      t.decimal :liquidation_price, precision: 28, scale: 8, null: false
      t.decimal :maintenance_margin, precision: 28, scale: 8, null: false
      t.decimal :unrealized_pnl, precision: 28, scale: 8, null: false, default: 0.0
      t.string :status, null: false
      t.timestamps
    end
  end
end
