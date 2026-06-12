# frozen_string_literal: true

module Strategy
  class PositionTracker
    REDIS_KEY_PREFIX = "strategy:position"

    attr_reader :redis

    def initialize(redis: MarketDataFeed.redis)
      @redis = redis
    end

    # Returns a hash with :side, :quantity, :entry_price or nil if no position
    #
    # @param symbol [String] Trading symbol (e.g., "BTCUSDT")
    # @return [Hash, nil] Hash with :side, :quantity, :entry_price or nil if no position
    def current_position(symbol)
      key = redis_key(symbol)
      data = redis.hgetall(key)
      return nil if data.nil? || data.empty?

      side = data["side"]
      quantity = data["quantity"]
      entry_price = data["entry_price"]

      return nil if side.nil? || side.to_s.strip.empty?
      return nil if quantity.nil? || quantity.to_s.strip.empty?
      return nil if entry_price.nil? || entry_price.to_s.strip.empty?

      {
        side: normalize_side(side),
        quantity: BigDecimal(quantity),
        entry_price: BigDecimal(entry_price)
      }
    rescue StandardError
      nil
    end

    # Stores position state as a Redis hash at key "strategy:position:#{symbol}"
    # Fields: side ("long" or "short"), quantity (string), entry_price (string)
    #
    # @param symbol [String] Trading symbol (e.g., "BTCUSDT")
    # @param side [Symbol, String] Position side (:long, :short, "long", "short")
    # @param quantity [BigDecimal, String, Numeric] Position quantity
    # @param entry_price [BigDecimal, String, Numeric] Entry price
    def set_position(symbol, side:, quantity:, entry_price:)
      key = redis_key(symbol)

      redis.pipelined do
        redis.hset(key, "side", side.to_s.downcase)
        redis.hset(key, "quantity", quantity.to_s)
        redis.hset(key, "entry_price", entry_price.to_s)
      end

      nil
    end

    # Removes the position hash for the symbol
    #
    # @param symbol [String] Trading symbol (e.g., "BTCUSDT")
    def clear_position(symbol)
      redis.del(redis_key(symbol))
      nil
    end

    private

    def redis_key(symbol)
      "#{REDIS_KEY_PREFIX}:#{symbol}"
    end

    def normalize_side(value)
      normalized = value.to_s.downcase.strip.to_sym
      normalized == :short ? :short : :long
    end
  end
end