# frozen_string_literal: true

require "bigdecimal"

module Exchanges
  module Binance
    class OrderMapper
      def self.to_binance(order_request)
        params = {
          symbol: order_request.symbol,
          side: order_request.side.to_s.upcase,
          type: order_request.order_type.to_s.upcase,
          quantity: order_request.quantity.to_f,
          newClientOrderId: order_request.client_order_id
        }

        params[:reduceOnly] = "true" if order_request.reduce_only

        case order_request.order_type.to_sym
        when :limit
          params[:price] = order_request.price.to_f
          params[:timeInForce] = "GTC"
        when :stop_market, :take_profit_market
          params[:stopPrice] = order_request.stop_price.to_f
        end

        params
      end

      def self.from_binance(response)
        OrderResponse.new(
          exchange_order_id: response["orderId"].to_s,
          client_order_id: response["clientOrderId"] || response["newClientOrderId"],
          status: response["status"].downcase.to_sym,
          filled_quantity: BigDecimal(response["executedQty"] || "0.0"),
          average_price: BigDecimal(response["avgPrice"] || "0.0"),
          raw_response: response
        )
      end
    end
  end
end
