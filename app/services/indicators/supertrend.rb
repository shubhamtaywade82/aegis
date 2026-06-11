# frozen_string_literal: true

module Indicators
  class Supertrend
    Result = Struct.new(
      :value,
      :direction,
      :upper_band,
      :lower_band,
      keyword_init: true
    )

    BULLISH = :bullish
    BEARISH = :bearish

    def self.calculate(candles:, period:, multiplier:)
      new(
        candles: candles,
        period: period,
        multiplier: multiplier
      ).calculate
    end

    attr_reader :candles,
                :period,
                :multiplier

    def initialize(candles:, period:, multiplier:)
      @candles = candles
      @period = period
      @multiplier = multiplier
    end

    def calculate
      results = Array.new(candles.size)

      atr =
        Indicators::ATR.calculate(
          candles: candles,
          period: period
        )

      previous_upper = nil
      previous_lower = nil
      previous_st = nil

      candles.each_with_index do |candle, index|
        next if atr[index].nil?

        hl2 = (candle.high + candle.low) / 2.0

        basic_upper = hl2 + multiplier * atr[index]
        basic_lower = hl2 - multiplier * atr[index]

        final_upper =
          if previous_upper.nil?
            basic_upper
          elsif candles[index - 1].close <= previous_upper
            [ basic_upper, previous_upper ].min
          else
            basic_upper
          end

        final_lower =
          if previous_lower.nil?
            basic_lower
          elsif candles[index - 1].close >= previous_lower
            [ basic_lower, previous_lower ].max
          else
            basic_lower
          end

        supertrend =
          if previous_st.nil?
            final_upper
          elsif previous_st == previous_upper
            candle.close <= final_upper ? final_upper : final_lower
          else
            candle.close >= final_lower ? final_lower : final_upper
          end

        direction =
          supertrend == final_lower ? BULLISH : BEARISH

        results[index] =
          Result.new(
            value: supertrend,
            direction: direction,
            upper_band: final_upper,
            lower_band: final_lower
          )

        previous_upper = final_upper
        previous_lower = final_lower
        previous_st = supertrend
      end

      results
    end
  end
end
