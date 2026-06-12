# frozen_string_literal: true

module Strategy
  class SignalMonitor
    REDIS_KEY_PREFIX = "strategy:supertrend:last_direction"

    attr_reader :redis

    def initialize(redis: MarketDataFeed.redis)
      @redis = redis
    end

    # Returns :bullish, :bearish, or nil
    def current_direction(symbol)
      data = redis.get("trading:supertrend:#{symbol}")
      return nil unless data

      parse_supertrend_data(data)
    rescue JSON::ParserError
      nil
    end

    # Returns :bullish, :bearish, or nil
    def previous_direction(symbol)
      data = redis.get("#{REDIS_KEY_PREFIX}:#{symbol}")
      return nil unless data

      normalize_direction(data.strip)
    rescue JSON::ParserError
      nil
    end

    # Stores normalized direction string in Redis
    def store_direction(symbol, direction)
      redis.set("#{REDIS_KEY_PREFIX}:#{symbol}", direction.to_s.downcase)
    end

    # Returns true only if both directions are present and different
    def flip_detected?(symbol)
      current = current_direction(symbol)
      previous = previous_direction(symbol)
      return false if current.nil? || previous.nil?

      current != previous
    end

    # Atomically reads current, compares with previous, stores current, returns result hash.
    # Returns { flipped: true/false, from: :bullish/:bearish/nil, to: :bullish/:bearish/nil }
    def update_and_check(symbol)
      previous = previous_direction(symbol)
      current = current_direction(symbol)

      store_direction(symbol, current) if current

      {
        flipped: previous.nil? ? false : (current != previous && !current.nil?),
        from: previous,
        to: current
      }
    end

    private

    def parse_supertrend_data(data)
      parsed = JSON.parse(data)
      direction_value = parsed["direction"]
      return nil unless direction_value

      normalize_direction(direction_value)
    rescue JSON::ParserError
      nil
    end

    def normalize_direction(value)
      return nil if value.nil? || value.to_s.strip.empty?

      normalized = value.to_s.strip.upcase
      case normalized
      when "BULLISH", "BUY", "LONG"
        :bullish
      when "BEARISH", "SELL", "SHORT"
        :bearish
      else
        nil
      end
    end
  end
end