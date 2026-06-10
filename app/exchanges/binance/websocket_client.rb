# frozen_string_literal: true

module Exchanges
  module Binance
    class WebsocketClient
      attr_reader :ws_url, :status, :last_heartbeat

      def initialize(ws_url: "wss://stream.binancefuture.com/ws")
        @ws_url = ws_url
        @status = :disconnected
        @last_heartbeat = nil
        @callbacks = {}
      end

      def connect(listen_key)
        @status = :connected
        @last_heartbeat = Time.now
        trigger(:connected, nil)
      end

      def on(event, &block)
        @callbacks[event.to_sym] = block
      end

      def disconnect
        @status = :disconnected
        trigger(:disconnected, nil)
      end

      def keep_alive!(rest_client, listen_key)
        rest_client.signed_request(:put, "/fapi/v1/listenKey", { listenKey: listen_key })
        @last_heartbeat = Time.now
      end

      private

      def trigger(event, data)
        @callbacks[event.to_sym]&.call(data)
      end
    end
  end
end
