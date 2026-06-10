# frozen_string_literal: true

class Candle
  attr_reader :open_time,
              :open,
              :high,
              :low,
              :close,
              :volume,
              :close_time,
              :quote_volume,
              :trade_count,
              :taker_buy_base_volume,
              :taker_buy_quote_volume

  def initialize(
    open_time:,
    open:,
    high:,
    low:,
    close:,
    volume:,
    close_time:,
    quote_volume:,
    trade_count:,
    taker_buy_base_volume:,
    taker_buy_quote_volume:
  )
    @open_time = open_time
    @open = open
    @high = high
    @low = low
    @close = close
    @volume = volume
    @close_time = close_time
    @quote_volume = quote_volume
    @trade_count = trade_count
    @taker_buy_base_volume = taker_buy_base_volume
    @taker_buy_quote_volume = taker_buy_quote_volume
    freeze
  end

  def bullish?
    close > open
  end

  def bearish?
    close < open
  end

  def body_size
    (close - open).abs
  end

  def range
    high - low
  end

  def midpoint
    (high + low) / 2.0
  end

  def typical_price
    (high + low + close) / 3.0
  end

  def true_range(previous_close = nil)
    return range if previous_close.nil?

    [
      range,
      (high - previous_close).abs,
      (low - previous_close).abs
    ].max
  end
end
