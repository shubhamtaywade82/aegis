# frozen_string_literal: true

require "bigdecimal"

module Strategy
  class OrderGenerator
    EQUITY_ALLOCATION = BigDecimal("0.30")
    QUANTITY_PRECISION = 6

    attr_reader :paper_engine

    def initialize(paper_engine:)
      @paper_engine = paper_engine
    end

    # Generates OrderRequest array for a signal flip.
    # @param symbol [String] Trading symbol e.g. "BTCUSDT"
    # @param current_price [BigDecimal] Current mark price
    # @param new_direction [Symbol] :bullish or :bearish
    # @param current_position [Hash, nil] Hash from PositionTracker: { side: :long/:short, quantity: BigDecimal, entry_price: BigDecimal }
    # @return [Array<OrderRequest>] Orders to execute (close first, then entry)
    def generate_orders(symbol:, current_price:, new_direction:, current_position:)
      return [] if current_price.nil? || current_price <= 0

      target_position_side = new_direction == :bullish ? :long : :short
      target_order_side = new_direction == :bullish ? :buy : :sell

      # Already aligned - no orders needed
      if current_position && current_position[:side] == target_position_side
        return []
      end

      orders = []

      # Close existing opposing position
      if current_position && current_position[:quantity] > 0
        close_side = current_position[:side] == :long ? :sell : :buy
        orders << OrderRequest.new(
          symbol: symbol,
          side: close_side,
          quantity: current_position[:quantity],
          order_type: :market,
          reduce_only: true
        )
      end

      # Compute entry quantity
      qty = compute_quantity(current_price)
      return orders if qty.nil? || qty <= 0

      # Open new position
      orders << OrderRequest.new(
        symbol: symbol,
        side: target_order_side,
        quantity: qty,
        order_type: :market,
        reduce_only: false
      )

      orders
    end

    private

    def compute_quantity(current_price)
      balance = BigDecimal(paper_engine.available_balance.to_s) * EQUITY_ALLOCATION
      price = BigDecimal(current_price.to_s)
      qty = balance / price
      qty.round(QUANTITY_PRECISION)
    rescue StandardError
      nil
    end
  end
end