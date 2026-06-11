# frozen_string_literal: true

module Exchanges
  module Binance
    class Client
      TESTNET_BASE_URL = "https://testnet.binancefuture.com"
      TESTNET_WS_URL = "wss://stream.binancefuture.com/ws"

      attr_reader :api_key, :api_secret

      def initialize(
        api_key: ENV["BINANCE_TESTNET_API_KEY"] || ENV["BINANCE_API_KEY"],
        api_secret: ENV["BINANCE_TESTNET_API_SECRET"] || ENV["BINANCE_API_SECRET"]
      )
        @api_key = api_key
        @api_secret = api_secret
      end
    end
  end
end
