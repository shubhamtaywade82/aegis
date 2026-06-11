# frozen_string_literal: true

require "bigdecimal"
require "securerandom"

module Exchanges
  module CoinDCX
    class Adapter < BaseAdapter
      attr_reader :client

      def initialize(api_key: nil, api_secret: nil)
        @client = RestClient.new(api_key: api_key, api_secret: api_secret)
      end

      def capabilities
        {
          market_orders: true,
          limit_orders: true,
          stop_market: true,
          take_profit_market: true,
          hedge_mode: false,
          reduce_only: true,
          websocket_positions: true,
          websocket_orders: true,
          funding_rates: true,
          bracket_orders: false
        }
      end

      def account
        {
          balance: BigDecimal("10000.0"),
          available_balance: BigDecimal("8000.0"),
          positions: []
        }
      end

      def positions
        []
      end

      def open_orders
        []
      end

      def latest_price(symbol)
        resolved_symbol = SymbolRegistry.resolve(:coindcx, symbol)
        BigDecimal("100.0")
      end

      def place_order(order_request)
        resolved_symbol = SymbolRegistry.resolve(:coindcx, order_request.symbol)
        precision = PrecisionRegistry.for(:coindcx, order_request.symbol)

        qty = order_request.quantity.round(precision[:quantity_precision])
        price = order_request.price ? order_request.price.round(precision[:price_precision]) : nil

        OrderResponse.new(
          exchange_order_id: "coindcx_#{SecureRandom.hex(6)}",
          client_order_id: order_request.client_order_id,
          status: :filled,
          filled_quantity: qty,
          average_price: price || BigDecimal("100.0"),
          raw_response: { success: true }
        )
      end

      def cancel_order(symbol:, order_id:)
        resolved_symbol = SymbolRegistry.resolve(:coindcx, symbol)
        {
          exchange_order_id: order_id,
          client_order_id: "coindcx_#{SecureRandom.hex(6)}",
          status: :cancelled
        }
      end

      def modify_order(order_id:, updates:)
        { success: true, order_id: order_id }
      end
    end
  end
end
