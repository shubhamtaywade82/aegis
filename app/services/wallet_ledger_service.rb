# frozen_string_literal: true

class WalletLedgerService
  class LedgerError < StandardError; end

  # Locks funds in user's FUTURES_COLLATERAL wallet when an order is placed
  def self.lock_funds!(user_id:, currency:, amount:, reference_id:)
    ActiveRecord::Base.transaction do
      wallet = Wallet.lock("FOR UPDATE").find_by!(
        user_id: user_id,
        currency: currency,
        balance_type: "FUTURES_COLLATERAL"
      )

      if wallet.available_balance < amount
        raise LedgerError, "Insufficient available margin balance to lock"
      end

      wallet.available_balance -= amount
      wallet.locked_balance += amount
      wallet.save!

      LedgerEntry.create!(
        wallet: wallet,
        amount: -amount,
        transaction_type: "ORDER_LOCK",
        reference_id: reference_id,
        created_at: Time.current
      )
    end
  end

  # Settle trade executed on the exchange
  def self.settle_trade!(user_id:, symbol:, side:, execution_price:, qty:, client_order_id:, leverage:)
    ActiveRecord::Base.transaction do
      # Lock order and update status
      order = Order.lock("FOR UPDATE").find_by!(client_order_id: client_order_id)
      return if order.status == "FILLED"

      order.update!(filled_quantity: qty, status: "FILLED")

      wallet = Wallet.lock("FOR UPDATE").find_by!(
        user_id: user_id,
        currency: "USDT",
        balance_type: "FUTURES_COLLATERAL"
      )

      # 0.05% Taker fee calculation
      fee = qty * execution_price * BigDecimal("0.0005")

      wallet.locked_balance -= fee
      wallet.save!

      LedgerEntry.create!(
        wallet: wallet,
        amount: -fee,
        transaction_type: "TRADE_FEE",
        reference_id: client_order_id,
        created_at: Time.current
      )

      # Sync and update or create local position
      update_position_registry!(user_id, symbol, side, qty, execution_price, leverage)
    end
  end

  private

  def self.update_position_registry!(user_id, symbol, side, qty, execution_price, leverage)
    position = DbPosition.lock("FOR UPDATE").find_or_initialize_by(
      user_id: user_id,
      symbol: symbol,
      status: "open"
    )

    if position.new_record?
      position.side = side
      position.leverage = leverage
      position.size = qty
      position.entry_price = execution_price
      position.maintenance_margin = qty * execution_price * BigDecimal("0.05") # 5% MMR
      position.liquidation_price = calculate_liquidation(side, execution_price, leverage)
      position.unrealized_pnl = BigDecimal("0.0")
    else
      if position.side == side
        # Increase size and calculate average entry price
        total_qty = position.size + qty
        avg_entry = ((position.entry_price * position.size) + (execution_price * qty)) / total_qty
        position.size = total_qty
        position.entry_price = avg_entry
        position.maintenance_margin = total_qty * avg_entry * BigDecimal("0.05")
        position.liquidation_price = calculate_liquidation(position.side, avg_entry, leverage)
      else
        # Reduce or close position
        if qty >= position.size
          remaining = qty - position.size
          pnl = calculate_pnl(position.side, position.entry_price, execution_price, position.size)
          record_realized_pnl!(user_id, pnl, client_order_id: nil)

          if remaining.positive?
            position.side = side
            position.size = remaining
            position.entry_price = execution_price
            position.maintenance_margin = remaining * execution_price * BigDecimal("0.05")
            position.liquidation_price = calculate_liquidation(side, execution_price, leverage)
          else
            position.status = "closed"
            position.size = BigDecimal("0.0")
          end
        else
          position.size -= qty
          pnl = calculate_pnl(position.side, position.entry_price, execution_price, qty)
          record_realized_pnl!(user_id, pnl, client_order_id: nil)
          position.maintenance_margin = position.size * position.entry_price * BigDecimal("0.05")
        end
      end
    end

    position.save!
  end

  def self.calculate_liquidation(side, entry_price, leverage)
    mmr = BigDecimal("0.05")
    lev = BigDecimal(leverage.to_s)
    if side.to_s.downcase == "buy" || side.to_s.downcase == "long"
      entry_price * (BigDecimal("1.0") - (BigDecimal("1.0") / lev) + mmr)
    else
      entry_price * (BigDecimal("1.0") + (BigDecimal("1.0") / lev) - mmr)
    end
  end

  def self.calculate_pnl(side, entry, exit, qty)
    if side.to_s.downcase == "buy" || side.to_s.downcase == "long"
      (exit - entry) * qty
    else
      (entry - exit) * qty
    end
  end

  def self.record_realized_pnl!(user_id, pnl, client_order_id:)
    wallet = Wallet.lock("FOR UPDATE").find_by!(
      user_id: user_id,
      currency: "USDT",
      balance_type: "FUTURES_COLLATERAL"
    )
    wallet.available_balance += pnl
    wallet.save!

    LedgerEntry.create!(
      wallet: wallet,
      amount: pnl,
      transaction_type: "REALIZED_PNL",
      reference_id: client_order_id || "position_adjust",
      created_at: Time.current
    )
  end
end
