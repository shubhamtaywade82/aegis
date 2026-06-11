# frozen_string_literal: true

require "bigdecimal"

module Execution
  class MatchingEngine
    def self.match(open_orders:, candle:, latest_price:, slippage_model:, symbol:)
      new(
        open_orders: open_orders,
        candle: candle,
        latest_price: latest_price,
        slippage_model: slippage_model,
        symbol: symbol
      ).match
    end

    attr_reader :open_orders, :candle, :latest_price, :slippage_model, :symbol

    def initialize(open_orders:, candle:, latest_price:, slippage_model:, symbol:)
      @open_orders = open_orders
      @candle = candle
      @latest_price = BigDecimal(latest_price.to_s)
      @slippage_model = slippage_model
      @symbol = symbol
    end

    def match
      fills = []

      open_orders.each do |order|
        next if order.symbol != symbol

        fill_price = should_fill?(order)
        next unless fill_price

        if %i[market stop_market take_profit_market].include?(order.order_type)
          fill_price = slippage_model.apply(price: fill_price, side: order.side)
        end

        fee_rate = BigDecimal("0.0005")
        fee = order.quantity * fill_price * fee_rate

        fills << Fill.new(
          order_id: order.client_order_id,
          symbol: order.symbol,
          side: order.side,
          quantity: order.quantity,
          price: fill_price,
          fee: fee
        )
      end

      fills
    end

    private

    def should_fill?(order)
      low = BigDecimal(candle.low.to_s)
      high = BigDecimal(candle.high.to_s)

      case order.order_type
      when :market
        latest_price
      when :limit
        if order.side == :buy && low <= order.price
          order.price
        elsif order.side == :sell && high >= order.price
          order.price
        end
      when :stop_market
        if order.side == :buy && high >= order.stop_price
          order.stop_price
        elsif order.side == :sell && low <= order.stop_price
          order.stop_price
        end
      when :take_profit_market
        if order.side == :buy && low <= order.stop_price
          order.stop_price
        elsif order.side == :sell && high >= order.stop_price
          order.stop_price
        end
      end
    end
  end
end
