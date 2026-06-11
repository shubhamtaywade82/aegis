# frozen_string_literal: true

require "securerandom"
require "bigdecimal"

module Execution
  class PaperEngine < Exchanges::BaseAdapter
    attr_reader :balance,
                :open_orders_list,
                :positions_list,
                :fees_paid,
                :trades_history,
                :initial_balance

    def initialize(initial_balance: 10_000.0)
      @initial_balance = BigDecimal(initial_balance.to_s)
      @balance = @initial_balance
      @open_orders_list = []
      @positions_list = []
      @fees_paid = BigDecimal("0.0")
      @trades_history = []
      @prices = {}
    end

    def set_price(symbol, price)
      @prices[symbol] = BigDecimal(price.to_s)
      update_unrealized_pnl!(symbol)
    end

    def latest_price(symbol)
      @prices[symbol]
    end

    def account
      {
        balance: balance,
        available_balance: available_balance,
        positions: positions_list
      }
    end

    def positions
      positions_list
    end

    def open_orders
      open_orders_list
    end

    def place_order(order_request)
      price = order_request.price || @prices[order_request.symbol]
      raise ArgumentError, "No price available for #{order_request.symbol}. Ensure market data feed is running." unless price

      fee_rate = BigDecimal("0.0005")
      notional = order_request.quantity * price
      fee_cost = notional * fee_rate
      @fees_paid += fee_cost
      @balance -= fee_cost

      if order_request.reduce_only
        pos = positions_list.find { |p| p.symbol == order_request.symbol }
        if pos
          if order_request.quantity >= pos.quantity
            positions_list.delete(pos)
            realized_pnl = calculate_pnl(pos.side, pos.entry_price, price, pos.quantity)
            @balance += realized_pnl
          else
            new_qty = pos.quantity - order_request.quantity
            positions_list.delete(pos)
            positions_list << PositionSnapshot.new(
              symbol: pos.symbol,
              side: pos.side,
              quantity: new_qty,
              entry_price: pos.entry_price,
              mark_price: price,
              unrealized_pnl: calculate_pnl(pos.side, pos.entry_price, price, new_qty)
            )
            realized_pnl = calculate_pnl(pos.side, pos.entry_price, price, order_request.quantity)
            @balance += realized_pnl
          end
        end
      else
        pos = positions_list.find { |p| p.symbol == order_request.symbol }
        if pos
          new_qty = pos.quantity + order_request.quantity
          new_entry = ((pos.entry_price * pos.quantity) + (price * order_request.quantity)) / new_qty
          positions_list.delete(pos)
          positions_list << PositionSnapshot.new(
            symbol: pos.symbol,
            side: pos.side,
            quantity: new_qty,
            entry_price: new_entry,
            mark_price: price,
            unrealized_pnl: calculate_pnl(pos.side, new_entry, price, new_qty)
          )
        else
          positions_list << PositionSnapshot.new(
            symbol: order_request.symbol,
            side: order_request.side == :buy ? :long : :short,
            quantity: order_request.quantity,
            entry_price: price,
            mark_price: price,
            unrealized_pnl: BigDecimal("0.0")
          )
        end
      end

      response = OrderResponse.new(
        exchange_order_id: SecureRandom.uuid,
        client_order_id: order_request.client_order_id,
        status: :filled,
        filled_quantity: order_request.quantity,
        average_price: price,
        raw_response: { paper: true }
      )

      @trades_history << response
      response
    end

    def cancel_order(symbol:, order_id:)
      order = open_orders_list.find { |o| o[:order_id] == order_id }
      if order
        open_orders_list.delete(order)
        { exchange_order_id: order_id, client_order_id: order[:client_order_id], status: :canceled }
      else
        raise ArgumentError, "Order not found"
      end
    end

    def available_balance
      balance + positions_list.sum(&:unrealized_pnl)
    end

    def drawdown
      equity = available_balance
      peak = [ initial_balance, equity ].max
      peak - equity
    end

    private

    def calculate_pnl(side, entry, exit, qty)
      case side
      when :long
        (exit - entry) * qty
      when :short
        (entry - exit) * qty
      else
        BigDecimal("0.0")
      end
    end

    def update_unrealized_pnl!(symbol)
      price = @prices[symbol]
      return unless price

      positions_list.each_with_index do |pos, idx|
        if pos.symbol == symbol
          positions_list[idx] = PositionSnapshot.new(
            symbol: pos.symbol,
            side: pos.side,
            quantity: pos.quantity,
            entry_price: pos.entry_price,
            mark_price: price,
            unrealized_pnl: calculate_pnl(pos.side, pos.entry_price, price, pos.quantity)
          )
        end
      end
    end
  end
end
