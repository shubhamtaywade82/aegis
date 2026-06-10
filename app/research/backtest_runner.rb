# frozen_string_literal: true

require_relative "candle_series"
require_relative "../indicators/atr"
require_relative "../indicators/supertrend"
require_relative "variant_simulator"
require_relative "metrics_calculator"

module Research
  module BacktestRunner
    module_function

    def call(
      candles:,
      period: 10,
      multiplier: 3.0,
      atr_stop_multiplier: 1.0,
      reward_risk_ratio: 2.0
    )
      candle_series =
        if candles.is_a?(Research::CandleSeries)
          candles
        else
          Research::CandleSeries.new(candles)
        end

      atr = Indicators::ATR.calculate(
        candles: candle_series.candles,
        period: period
      )

      supertrend = Indicators::Supertrend.calculate(
        candles: candle_series.candles,
        period: period,
        multiplier: multiplier
      )

      trades = Research::VariantSimulator.new(
        candles: candle_series.candles,
        supertrend: supertrend,
        atr: atr,
        atr_stop_multiplier: atr_stop_multiplier,
        reward_risk_ratio: reward_risk_ratio
      ).call

      Research::MetricsCalculator.new(trades).call
    end
  end
end
