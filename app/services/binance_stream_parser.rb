# frozen_string_literal: true

# Top-level parser class
class BinanceStreamParser
    ParseResult = Struct.new(:stream, :event_type, :symbol, :data, keyword_init: true)

    # Parses a raw WebSocket JSON message.
    #
    # @param message [String, Hash] Raw WebSocket message (JSON string or already-parsed hash)
    # @return [ParseResult, nil] Parsed result or nil if parsing fails
    def self.parse(message)
      data = message.is_a?(String) ? JSON.parse(message) : message

      # Combined stream format: { "stream": "btcusdt@ticker", "data": { ... } }
      if data.key?("stream") && data.key?("data")
        stream = data["stream"]
        event_data = data["data"]
        event_type = event_data["e"] if event_data.is_a?(Hash)
        symbol = extract_symbol(stream)
        ParseResult.new(stream: stream, event_type: event_type, symbol: symbol, data: event_data)
      else
        # Single stream format: { "e": "24hrTicker", "s": "BTCUSDT", ... }
        event_type = data["e"] if data.is_a?(Hash)
        symbol = data["s"] if data.is_a?(Hash)
        ParseResult.new(stream: nil, event_type: event_type, symbol: symbol, data: data)
      end
    rescue JSON::ParserError, StandardError
      nil
    end

    # Extracts symbol from stream name like "btcusdt@ticker" or "btcusdt@kline_1m"
    #
    # @param stream [String, nil] Stream name
    # @return [String, nil] Uppercase symbol or nil
    def self.extract_symbol(stream)
      return nil unless stream

      stream.split("@").first&.upcase
    end
end
