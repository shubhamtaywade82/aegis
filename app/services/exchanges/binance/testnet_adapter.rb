# frozen_string_literal: true

require "openssl"
require "faraday"
require "json"
require "bigdecimal"
require_relative "../base_adapter"
require_relative "../../settings/binance_settings"
require_relative "../../value_objects/position_snapshot"
require_relative "../../value_objects/order_response"
require_relative "../../errors/external_service_error"

module Exchanges
  module Binance
    class TestnetAdapter < BaseAdapter
      def initialize(
        api_key: ENV["BINANCE_TESTNET_API_KEY"] || ENV["BINANCE_API_KEY"],
        api_secret: ENV["BINANCE_TESTNET_API_SECRET"] || ENV["BINANCE_API_SECRET"],
        base_url: ENV["BINANCE_TESTNET_BASE_URL"] || "https://testnet.binancefuture.com"
      )
        @api_key = api_key
        @api_secret = api_secret
        @base_url = base_url
      end

      def account
        response = signed_request(:get, "/fapi/v2/account")
        {
          balance: BigDecimal(response["totalMarginBalance"] || "0.0"),
          available_balance: BigDecimal(response["availableBalance"] || "0.0"),
          positions: response["positions"]
        }
      end

      def positions
        response = signed_request(:get, "/fapi/v2/positionRisk")
        response.map do |pos|
          qty = BigDecimal(pos["positionAmt"] || "0.0")
          next if qty.zero?

          side = qty.positive? ? :long : :short

          PositionSnapshot.new(
            symbol: pos["symbol"],
            side: side,
            quantity: qty.abs,
            entry_price: BigDecimal(pos["entryPrice"] || "0.0"),
            mark_price: BigDecimal(pos["markPrice"] || "0.0"),
            unrealized_pnl: BigDecimal(pos["unRealizedProfit"] || "0.0")
          )
        end.compact
      end

      def open_orders
        response = signed_request(:get, "/fapi/v1/openOrders")
        response.map do |ord|
          {
            order_id: ord["orderId"].to_s,
            client_order_id: ord["clientOrderId"],
            symbol: ord["symbol"],
            side: ord["side"].downcase.to_sym,
            price: BigDecimal(ord["price"] || "0.0"),
            quantity: BigDecimal(ord["origQty"] || "0.0"),
            status: ord["status"].downcase.to_sym
          }
        end
      end

      def place_order(order_request)
        params = {
          symbol: order_request.symbol,
          side: order_request.side.to_s.upcase,
          type: order_request.order_type.to_s.upcase,
          quantity: order_request.quantity.to_f,
          newClientOrderId: order_request.client_order_id
        }

        params[:reduceOnly] = "true" if order_request.reduce_only

        case order_request.order_type
        when :limit
          params[:price] = order_request.price.to_f
          params[:timeInForce] = "GTC"
        when :stop_market, :take_profit_market
          params[:stopPrice] = order_request.stop_price.to_f
        end

        response = signed_request(:post, "/fapi/v1/order", params)

        OrderResponse.new(
          exchange_order_id: response["orderId"].to_s,
          client_order_id: response["clientOrderId"],
          status: response["status"].downcase.to_sym,
          filled_quantity: BigDecimal(response["executedQty"] || "0.0"),
          average_price: BigDecimal(response["avgPrice"] || "0.0"),
          raw_response: response
        )
      end

      def cancel_order(symbol:, order_id:)
        params = {
          symbol: symbol,
          orderId: order_id
        }
        response = signed_request(:delete, "/fapi/v1/order", params)
        {
          exchange_order_id: response["orderId"].to_s,
          client_order_id: response["clientOrderId"],
          status: response["status"].downcase.to_sym
        }
      end

      def latest_price(symbol)
        params = { symbol: symbol }
        response = connection.get("/fapi/v1/ticker/price", params)

        unless response.success?
          raise ExternalServiceError.new(
            "Binance API Error: #{response.body}",
            service: :binance
          )
        end

        data = JSON.parse(response.body)
        BigDecimal(data["price"] || "0.0")
      end

      private

      def connection
        @connection ||= Faraday.new(url: @base_url) do |f|
          f.request :url_encoded
          f.adapter Faraday.default_adapter
        end
      end

      def signed_request(method, path, params = {})
        timestamp = Time.now.to_i * 1000
        payload = params.merge(timestamp: timestamp)

        query_string = URI.encode_www_form(payload)

        signature = OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest.new("sha256"),
          @api_secret.to_s,
          query_string
        )

        query_string += "&signature=#{signature}"

        headers = {
          "X-MBX-APIKEY" => @api_key.to_s,
          "Content-Type" => "application/x-www-form-urlencoded"
        }

        response =
          case method.to_sym
          when :get
            connection.get("#{path}?#{query_string}", nil, headers)
          when :post
            connection.post(path, query_string, headers)
          when :delete
            connection.delete("#{path}?#{query_string}", nil, headers)
          end

        unless response.success?
          raise ExternalServiceError.new(
            "Binance API Error: #{response.body}",
            service: :binance,
            context: { status: response.status, body: response.body }
          )
        end

        JSON.parse(response.body)
      end
    end
  end
end
