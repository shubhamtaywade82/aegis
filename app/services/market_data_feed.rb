# frozen_string_literal: true

require "redis"
require "json"
require_relative "../value_objects/candle"
require_relative "binance_stream_parser"

class MarketDataFeed
  STREAM_BASE_URL = "wss://fstream.binance.com/stream".freeze
  TICK_TTL = 60
  KLINE_TTL = 60
  MAX_HISTORY_SIZE = 500

    attr_reader :symbols, :ws_client, :redis

    # @param symbols [Array<String>] List of trading symbols (e.g., %w[BTCUSDT ETHUSDT SOLUSDT])
    def initialize(symbols: %w[BTCUSDT ETHUSDT SOLUSDT])
      @symbols = symbols
      @ws_client = nil
      @redis = Redis.new
      @running = false
    end

    # Starts the market data feed by connecting to the Binance combined stream.
    def start
      return if @running

      @running = true
      combined_url = build_combined_stream_url

      @ws_client = Exchanges::Binance::WebsocketClient.new(ws_url: combined_url)

      @ws_client.on(:connected) do |_event|
        Rails.logger.info "[MarketDataFeed] Connected to Binance combined stream: #{symbols.join(', ')}"
      end

      @ws_client.on(:message) do |data|
        process_message(data)
      end

      @ws_client.on(:error) do |error|
        Rails.logger.error "[MarketDataFeed] WebSocket error: #{error}"
      end

      @ws_client.on(:disconnected) do |_event|
        Rails.logger.warn "[MarketDataFeed] WebSocket disconnected"
      end

      @ws_client.connect
    end

    # Stops the market data feed gracefully.
    def stop
      @running = false
      @ws_client&.disconnect
      @redis&.close
    end


# Class-level accessors for controllers/views without instantiating the feed
def self.redis
  @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
end

def self.latest_tick(symbol)
  data = redis.get("trading:ticks:#{symbol}")
  data ? JSON.parse(data) : nil
end

def self.latest_kline(symbol)
  data = redis.get("trading:klines:#{symbol}")
  data ? JSON.parse(data) : nil
end

    # Retrieves the latest tick data for a symbol from Redis.
    #
    # @param symbol [String] Trading symbol (e.g., "BTCUSDT")
    # @return [Hash, nil] Tick data hash or nil if not found
    def latest_tick(symbol)
      data = @redis.get("trading:ticks:#{symbol}")
      data ? JSON.parse(data) : nil
    end

    # Retrieves the latest (potentially open) kline data for a symbol from Redis.
    #
    # @param symbol [String] Trading symbol (e.g., "BTCUSDT")
    # @return [Hash, nil] Kline data hash or nil if not found
    def latest_kline(symbol)
      data = @redis.get("trading:klines:#{symbol}")
      data ? JSON.parse(data) : nil
    end

    # Retrieves closed klines from history.
    #
    # @param symbol [String] Trading symbol (e.g., "BTCUSDT")
    # @param count [Integer] Number of klines to retrieve (default 30)
    # @return [Array<Hash>] Array of closed kline data hashes
    def closed_klines(symbol, count: 30)
      @redis.lrange("trading:klines:#{symbol}:history", 0, count - 1).map do |item|
        JSON.parse(item)
      end
    end

    # Processes a raw WebSocket message and updates Redis + broadcasts via ActionCable.
    #
    # @param message [Hash] Parsed JSON message from WebSocket
    def process_message(message)
      result = BinanceStreamParser.parse(message)
      return unless result

      case result.event_type
      when "24hrTicker"
        process_ticker(result.symbol, result.data)
      when "kline"
        process_kline(result.symbol, result.data)
      end
    rescue StandardError => e
      Rails.logger.error "[MarketDataFeed] Error processing message: #{e.message}"
    end

    private

    # Builds the combined stream WebSocket URL for all symbols.
    #
    # @return [String] Combined stream URL
    def build_combined_stream_url
      streams = symbols.flat_map do |symbol|
        [ "#{symbol.downcase}@ticker", "#{symbol.downcase}@kline_1m" ]
      end.join("/")

      "#{STREAM_BASE_URL}?streams=#{streams}"
    end

    # Processes a ticker event and stores/broadcasts it.
    #
    # @param symbol [String] Trading symbol
    # @param data [Hash] Ticker event data
    def process_ticker(symbol, data)
      return unless symbol && data

      # Store in Redis with TTL
      @redis.setex("trading:ticks:#{symbol}", TICK_TTL, data.to_json)

      # Broadcast via ActionCable (JSON for client consumption)
      broadcast(symbol, {
        type: "ticker",
        symbol: symbol,
        price: data["c"],
        open: data["o"],
        high: data["h"],
        low: data["l"],
        volume: data["v"],
        quote_volume: data["q"],
        timestamp: Time.current.iso8601
      })

      # Broadcast Turbo Stream update for price card
      broadcast_price_update(symbol, data)
    end

    # Processes a kline event and stores/broadcasts it.
    #
    # @param symbol [String] Trading symbol
    # @param data [Hash] Kline event data with "k" key containing kline fields
    def process_kline(symbol, data)
      return unless symbol && data

      kline_data = data["k"]
      return unless kline_data

      # Store latest kline in Redis with TTL
      @redis.setex("trading:klines:#{symbol}", KLINE_TTL, kline_data.to_json)

      # If kline is closed, push to history
      if kline_data["x"]
        candle = build_candle(kline_data)
        candle_json = candle_to_json(candle)

        # Push to history list and trim
        @redis.lpush("trading:klines:#{symbol}:history", candle_json)
        @redis.ltrim("trading:klines:#{symbol}:history", 0, MAX_HISTORY_SIZE - 1)

        # Broadcast closed kline
        broadcast(symbol, {
          type: "kline_closed",
          symbol: symbol,
          candle: candle_json
        })
      end
    end

    # Builds a Candle value object from kline data.
    #
    # @param kline_data [Hash] Kline data hash
    # @return [Candle] Candle value object
    def build_candle(kline_data)
      Candle.new(
        open_time: Time.at(kline_data["t"] / 1000),
        open: BigDecimal(kline_data["o"]),
        high: BigDecimal(kline_data["h"]),
        low: BigDecimal(kline_data["l"]),
        close: BigDecimal(kline_data["c"]),
        volume: BigDecimal(kline_data["v"]),
        close_time: Time.at(kline_data["T"] / 1000),
        quote_volume: BigDecimal(kline_data["q"]),
        trade_count: kline_data["n"],
        taker_buy_base_volume: BigDecimal(kline_data["V"]),
        taker_buy_quote_volume: BigDecimal(kline_data["Q"])
      )
    end

    # Converts a Candle to JSON-compatible hash.
    #
    # @param candle [Candle] Candle value object
    # @return [Hash] JSON-compatible hash
    def candle_to_json(candle)
      {
        open_time: candle.open_time.to_i,
        open: candle.open.to_s,
        high: candle.high.to_s,
        low: candle.low.to_s,
        close: candle.close.to_s,
        volume: candle.volume.to_s,
        close_time: candle.close_time.to_i
      }
    end

    # Broadcasts a message to the trading channel for a symbol.
    #
    # @param symbol [String] Trading symbol
    # @param payload [Hash] Message payload
    def broadcast(symbol, payload)
      ActionCable.server.broadcast("trading:#{symbol}", payload)
    end

    # Broadcasts a Turbo Stream replace for the price card.
    #
    # @param symbol [String] Trading symbol
    # @param tick [Hash] Ticker data
    def broadcast_price_update(symbol, tick)
      broadcast_turbo_stream(
        symbol,
        action: :replace,
        target: "price-card-#{symbol}",
        partial: "dashboard/price",
        locals: { tick: tick, symbol: symbol }
      )
    end

    # Broadcasts a Turbo Stream replace for the kline card.
    #
    # @param symbol [String] Trading symbol
    # @param kline [Hash] Kline data
    def broadcast_kline_update(symbol, kline)
      broadcast_turbo_stream(
        symbol,
        action: :replace,
        target: "kline-card-#{symbol}",
        partial: "dashboard/kline",
        locals: { kline: kline, symbol: symbol }
      )
    end

    private

    # Helper to broadcast a Turbo Stream message.
    #
    # @param symbol [String] Trading symbol
    # @param action [Symbol] Turbo stream action (:replace, :update, etc.)
    # @param target [String] DOM target ID
    # @param partial [String] Partial path
    # @param locals [Hash] Local variables for the partial
    def broadcast_turbo_stream(symbol, action:, target:, partial:, locals:)
      Turbo::StreamsChannel.broadcast_replace_to(
        "trading:#{symbol}",
        target: target,
        partial: partial,
        locals: locals.merge(symbol: symbol)
      )
    rescue NameError
      # Turbo::StreamsChannel not available (e.g., in test without turbo-rails)
      Rails.logger.debug "Turbo::StreamsChannel not available for broadcast"
    end
end
