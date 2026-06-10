# frozen_string_literal: true

require "redis"
require "json"

class MatchingEngine
  REDIS_URL = ENV.fetch("REDIS_URL", "redis://localhost:6379/1")

  def self.redis
    @redis ||= Redis.new(url: REDIS_URL)
  end

  # Cache ticker tick updates to Redis ticker cache hash and check triggers
  def self.process_ticker_tick(symbol, current_ltp)
    price_val = BigDecimal(current_ltp.to_s)

    # 1. Update Ticker Cache
    redis.hset("market:ticker:#{symbol}", {
      "ltp" => price_val.to_s,
      "timestamp" => Time.now.to_i.to_s
    })

    # 2. Evaluate Conditional Trigger indexes
    # Buy stops/limits: triggers if price is less than or equal to trigger price
    triggered_buys = redis.zrangebyscore("orders:trigger:buy:#{symbol}", price_val.to_s, "+inf")
    triggered_buys.each do |client_order_id|
      if redis.zrem("orders:trigger:buy:#{symbol}", client_order_id) > 0
        execute_local_order_async(client_order_id, price_val)
      end
    end

    # Sell stops/limits: triggers if price is greater than or equal to trigger price
    triggered_sells = redis.zrangebyscore("orders:trigger:sell:#{symbol}", "-inf", price_val.to_s)
    triggered_sells.each do |client_order_id|
      if redis.zrem("orders:trigger:sell:#{symbol}", client_order_id) > 0
        execute_local_order_async(client_order_id, price_val)
      end
    end
  end

  def self.execute_local_order_async(client_order_id, execution_price)
    OrderExecutionJob.perform_later(client_order_id, execution_price.to_s)
  end
end
