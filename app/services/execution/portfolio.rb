# frozen_string_literal: true

require "bigdecimal"

module Execution
  class Portfolio
    attr_accessor :cash_balance, :realized_pnl, :leverage
    attr_reader :positions, :open_orders, :closed_trades, :daily_pnl

    def initialize(cash_balance: 10_000.0, leverage: 10)
      @cash_balance = BigDecimal(cash_balance.to_s)
      @realized_pnl = BigDecimal("0.0")
      @leverage = leverage
      @positions = {}
      @open_orders = []
      @closed_trades = []
      @daily_pnl = BigDecimal("0.0")
    end

    def equity
      cash_balance + unrealized_pnl
    end

    def used_margin
      notional = positions.values.sum { |pos| pos.quantity * pos.mark_price }
      (notional / BigDecimal(leverage.to_s)).round(8)
    end

    def available_margin
      [ equity - used_margin, BigDecimal("0.0") ].max
    end

    def unrealized_pnl
      positions.values.sum(&:unrealized_pnl)
    end

    def update_mark_price!(symbol, mark_price)
      pos = positions[symbol]
      return unless pos

      price = BigDecimal(mark_price.to_s)
      pnl = calculate_pnl(pos.side, pos.entry_price, price, pos.quantity)

      positions[symbol] = PositionSnapshot.new(
        symbol: symbol,
        side: pos.side,
        quantity: pos.quantity,
        entry_price: pos.entry_price,
        mark_price: price,
        unrealized_pnl: pnl
      )
    end

    def add_position(symbol, side, quantity, entry_price)
      price = BigDecimal(entry_price.to_s)
      qty = BigDecimal(quantity.to_s)
      existing = positions[symbol]

      if existing
        if existing.side == side.to_sym
          total_qty = existing.quantity + qty
          avg_entry = ((existing.entry_price * existing.quantity) + (price * qty)) / total_qty
          pnl = calculate_pnl(side, avg_entry, price, total_qty)

          positions[symbol] = PositionSnapshot.new(
            symbol: symbol,
            side: side,
            quantity: total_qty,
            entry_price: avg_entry,
            mark_price: price,
            unrealized_pnl: pnl
          )
        else
          if qty >= existing.quantity
            close_qty = existing.quantity
            rem_qty = qty - close_qty

            pnl = calculate_pnl(existing.side, existing.entry_price, price, close_qty)
            record_closed_trade(existing.entry_price, price, close_qty, pnl)

            positions.delete(symbol)

            if rem_qty.positive?
              positions[symbol] = PositionSnapshot.new(
                symbol: symbol,
                side: side,
                quantity: rem_qty,
                entry_price: price,
                mark_price: price,
                unrealized_pnl: BigDecimal("0.0")
              )
            end
          else
            new_qty = existing.quantity - qty
            pnl = calculate_pnl(existing.side, existing.entry_price, price, qty)
            record_closed_trade(existing.entry_price, price, qty, pnl)

            positions[symbol] = PositionSnapshot.new(
              symbol: symbol,
              side: existing.side,
              quantity: new_qty,
              entry_price: existing.entry_price,
              mark_price: price,
              unrealized_pnl: calculate_pnl(existing.side, existing.entry_price, price, new_qty)
            )
          end
        end
      else
        positions[symbol] = PositionSnapshot.new(
          symbol: symbol,
          side: side,
          quantity: qty,
          entry_price: price,
          mark_price: price,
          unrealized_pnl: BigDecimal("0.0")
        )
      end
    end

    def serialize
      {
        "cash_balance" => cash_balance.to_s,
        "realized_pnl" => realized_pnl.to_s,
        "leverage" => leverage,
        "daily_pnl" => daily_pnl.to_s,
        "positions" => positions.transform_values { |p| position_to_h(p) },
        "open_orders" => open_orders,
        "closed_trades" => closed_trades.map { |t| trade_to_h(t) }
      }
    end

    def self.restore(hash)
      portfolio = new(
        cash_balance: BigDecimal(hash["cash_balance"]),
        leverage: hash["leverage"].to_i
      )
      portfolio.realized_pnl = BigDecimal(hash["realized_pnl"])

      hash["positions"].each do |symbol, pos_data|
        portfolio.positions[symbol] = PositionSnapshot.new(
          symbol: pos_data["symbol"],
          side: pos_data["side"].to_sym,
          quantity: BigDecimal(pos_data["quantity"]),
          entry_price: BigDecimal(pos_data["entry_price"]),
          mark_price: BigDecimal(pos_data["mark_price"]),
          unrealized_pnl: BigDecimal(pos_data["unrealized_pnl"])
        )
      end

      portfolio.open_orders.replace(hash["open_orders"] || [])

      hash["closed_trades"].each do |trade_data|
        portfolio.closed_trades << ClosedTrade.new(
          entry_price: BigDecimal(trade_data["entry_price"]),
          exit_price: BigDecimal(trade_data["exit_price"]),
          quantity: BigDecimal(trade_data["quantity"]),
          fees: BigDecimal(trade_data["fees"]),
          realized_pnl: BigDecimal(trade_data["realized_pnl"]),
          holding_period: trade_data["holding_period"].to_i,
          exit_reason: trade_data["exit_reason"]
        )
      end

      portfolio
    end

    private

    def calculate_pnl(side, entry, exit, qty)
      case side.to_sym
      when :long
        (exit - entry) * qty
      when :short
        (entry - exit) * qty
      else
        BigDecimal("0.0")
      end
    end

    def record_closed_trade(entry_price, exit_price, quantity, pnl)
      @realized_pnl += pnl
      @cash_balance += pnl
      @daily_pnl += pnl

      closed_trades << ClosedTrade.new(
        entry_price: entry_price,
        exit_price: exit_price,
        quantity: quantity,
        fees: BigDecimal("0.0"),
        realized_pnl: pnl,
        holding_period: 0,
        exit_reason: "market_order"
      )
    end

    def position_to_h(p)
      {
        "symbol" => p.symbol,
        "side" => p.side.to_s,
        "quantity" => p.quantity.to_s,
        "entry_price" => p.entry_price.to_s,
        "mark_price" => p.mark_price.to_s,
        "unrealized_pnl" => p.unrealized_pnl.to_s
      }
    end

    def trade_to_h(t)
      {
        "entry_price" => t.entry_price.to_s,
        "exit_price" => t.exit_price.to_s,
        "quantity" => t.quantity.to_s,
        "fees" => t.fees.to_s,
        "realized_pnl" => t.realized_pnl.to_s,
        "holding_period" => t.holding_period,
        "exit_reason" => t.exit_reason
      }
    end
  end
end
