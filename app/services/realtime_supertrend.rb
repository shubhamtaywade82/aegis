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
    klines_json.map do |item|
      begin
        parsed = item.is_a?(String) ? JSON.parse(item) : item
        parse_kline(parsed)
      rescue => e
        nil
      end
    end.compact.reverse
  end

  private_class_method def self.parse_kline(k)
    return nil unless k.is_a?(Hash)

    open_time = k["open_time"] || k["t"]
    open = k["open"] || k["o"]
    high = k["high"] || k["h"]
    low = k["low"] || k["l"]
    close = k["close"] || k["c"]
    volume = k["volume"] || k["v"]
    close_time = k["close_time"] || (open_time ? open_time + 59_999 : nil)

    return nil if open.nil? || high.nil? || low.nil? || close.nil?

    Candle.new(
      open_time: open_time,
      open: BigDecimal(open.to_s),
      high: BigDecimal(high.to_s),
      low: BigDecimal(low.to_s),
      close: BigDecimal(close.to_s),
      volume: BigDecimal(volume.to_s),
      close_time: close_time,
      quote_volume: BigDecimal("0"),
      trade_count: 0,
      taker_buy_base_volume: BigDecimal("0"),
      taker_buy_quote_volume: BigDecimal("0")
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

    # Broadcast Turbo Stream replace for the supertrend card
    begin
      Turbo::StreamsChannel.broadcast_replace_to(
        "trading:#{symbol}",
        target: "supertrend-card-#{symbol}",
        partial: "dashboard/supertrend",
        locals: { supertrend: result, symbol: symbol }
      )
    rescue => e
      Rails.logger.error "[RealtimeSupertrend] Failed to broadcast Turbo Stream: #{e.message}"
    end
  end
end