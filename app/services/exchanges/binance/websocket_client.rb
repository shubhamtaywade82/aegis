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
      # @param listen_key [String, nil] Optional listen key for authenticated streams
      def connect(listen_key = nil)
        url = build_url(listen_key)
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
            EM.stop if EM.reactor_running?
          end

          @ws.on :error do |event|
            trigger(:error, event.message)
          end
        end
      rescue StandardError => e
        @status = :disconnected
        trigger(:error, "WebSocket Client encountered connection error: #{e.message}")
      end

      # Reconnects with exponential backoff.
      # @param max_attempts [Integer] Maximum number of reconnection attempts (default 5)
      def reconnect_with_backoff(max_attempts: 5)
        delays = [ 2, 4, 8, 16, 32 ].take(max_attempts - 1)

        # First attempt has no delay
        begin
          connect
          return true
        rescue StandardError => e
          Rails.logger.error "[WebsocketClient] Reconnection failed: #{e.message}"
          disconnect if @ws
        end

        # Retry attempts with exponential backoff
        delays.each_with_index do |delay, retry_attempt|
          Rails.logger.info "[WebsocketClient] Reconnecting (attempt #{retry_attempt + 2}/#{max_attempts}) in #{delay}s..."
          sleep(delay)

          begin
            connect
            return true
          rescue StandardError => e
            Rails.logger.error "[WebsocketClient] Reconnection failed: #{e.message}"
            disconnect if @ws
          end
        end

        Rails.logger.error "[WebsocketClient] All #{max_attempts} reconnection attempts failed"
        false
      end

      def on(event, &block)
        @callbacks[event.to_sym] = block
      end

      def disconnect
        @ws&.close
        @status = :disconnected
        trigger(:disconnected, nil)
      end

      private

      def build_url(listen_key = nil)
        url = @ws_url

        # Combined stream URLs already contain /stream, don't append /ws
        if url.include?("/stream")
          return listen_key ? "#{url}/#{listen_key}" : url
        end

        # Standard single-stream URL
        url += "/ws" unless url.end_with?("/ws")
        listen_key ? "#{url}/#{listen_key}" : url
      end

      def send_json(payload)
        @ws&.send(payload.to_json)
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
