# frozen_string_literal: true

module Exchanges
  module CoinDCX
    class WsClient
      attr_reader :url

      def initialize(url = "wss://stream.coindcx.com")
        @url = url
        @connected = false
      end

      def connect
        @connected = true
      end

      def disconnect
        @connected = false
      end

      def connected?
        @connected
      end
    end
  end
end
