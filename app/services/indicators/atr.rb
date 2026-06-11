# frozen_string_literal: true

module Indicators
  class ATR
    def self.calculate(candles:, period:)
      new(candles:, period:).calculate
    end

    attr_reader :candles, :period

    def initialize(candles:, period:)
      @candles = candles
      @period = period
    end

    def calculate
      return [] if candles.empty?

      tr_values = true_ranges

      atr = Array.new(candles.size)

      return atr if candles.size < period

      initial_atr =
        tr_values
          .first(period)
          .sum / period.to_f

      atr[period - 1] = initial_atr

      ((period)...candles.size).each do |i|
        atr[i] =
          (
            atr[i - 1] * (period - 1) +
            tr_values[i]
          ) / period.to_f
      end

      atr
    end

    private

    def true_ranges
      candles.each_with_index.map do |candle, index|
        if index.zero?
          candle.high - candle.low
        else
          previous_close = candles[index - 1].close

          [
            candle.high - candle.low,
            (candle.high - previous_close).abs,
            (candle.low - previous_close).abs
          ].max
        end
      end
    end
  end
end
