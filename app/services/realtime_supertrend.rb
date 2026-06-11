# frozen_string_literal: true

class RealtimeSupertrend
  SUPERTREND_TTL = 60

  def self.calculate_for(symbol)
    candles = fetch_candles(symbol)

    return nil if candles.size < 2

    results = Indicators::Supertrend.calculate(
      candles: candles,
      period: 10,
      multiplier: 3.0
    )

    result = results.compact.last
    return nil unless result

    store_result(symbol, result)
    broadcast_result(symbol, result)

    result
  end

  def self.latest_for(symbol)
    data = redis.get("trading:supertrend:#{symbol}")
    return nil unless data

    JSON.parse(data).transform_keys(&:to_sym)
  end

  private_class_method def self.redis
    MarketDataFeed.redis
  end

  private_class_method def self.fetch_candles(symbol)
    klines_json = redis.lrange("trading:klines:#{symbol}:history", 0, 29)
    klines_json.map { |json| parse_kline(JSON.parse(json)) }.reverse
  end

  private_class_method def self.parse_kline(k)
    Candle.new(
      open_time: k["t"],
      open: k["o"],
      high: k["h"],
      low: k["l"],
      close: k["c"],
      volume: k["v"],
      close_time: k["t"] + 59_999,
      quote_volume: "0",
      trade_count: "0",
      taker_buy_base_volume: "0",
      taker_buy_quote_volume: "0"
    )
  end

  private_class_method def self.store_result(symbol, result)
    data = {
      direction: result.direction.to_s.upcase,
      value: result.value,
      upper_band: result.upper_band,
      lower_band: result.lower_band
    }
    redis.setex("trading:supertrend:#{symbol}", SUPERTREND_TTL, data.to_json)
  end

  private_class_method def self.broadcast_result(symbol, result)
    ActionCable.server.broadcast("trading:#{symbol}", {
      type: "supertrend",
      symbol: symbol,
      direction: result.direction.to_s.upcase,
      value: result.value,
      upper_band: result.upper_band,
      lower_band: result.lower_band
    })
  end
end