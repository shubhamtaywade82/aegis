# frozen_string_literal: true

require "faye/websocket"
require "eventmachine"
require "json"

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

      # Connects using EventMachine and Faye::WebSocket
      def connect(listen_key = nil)
        url = listen_key ? "#{@ws_url}/#{listen_key}" : @ws_url
        @status = :connecting

        EM.run do
          @ws = Faye::WebSocket::Client.new(url)

          @ws.on :open do |event|
            @status = :connected
            @last_heartbeat = Time.now
            trigger(:connected, event)
          end

          @ws.on :message do |event|
            @last_heartbeat = Time.now
            begin
              data = JSON.parse(event.data)
              trigger(:message, data)
            rescue StandardError => e
              trigger(:error, "Failed to parse message JSON: #{e.message}")
            end
          end

          @ws.on :close do |event|
            @status = :disconnected
            trigger(:disconnected, event)
            EM.stop
          end

          @ws.on :error do |event|
            trigger(:error, event.message)
          end
        end
      rescue StandardError => e
        @status = :disconnected
        trigger(:error, "WebSocket Client encountered connection error: #{e.message}")
      end

      def on(event, &block)
        @callbacks[event.to_sym] = block
      end

      def disconnect
        @ws&.close
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
