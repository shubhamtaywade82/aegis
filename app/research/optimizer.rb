# frozen_string_literal: true

require_relative "backtest_runner"
require_relative "../value_objects/optimization_result"

module Research
  class Optimizer
    LENGTH_START = 5
    LENGTH_END = 14

    MULTIPLIER_START = 1.0
    MULTIPLIER_STEP = 0.1
    MULTIPLIER_VARIANTS = 10

    def self.call(candles:)
      new(candles: candles).call
    end

    attr_reader :candles

    def initialize(candles:)
      @candles = candles
    end

    def call
      results = []

      lengths.each do |length|
        multipliers.each do |multiplier|
          report =
            Research::BacktestRunner.call(
              candles: candles,
              period: length,
              multiplier: multiplier,
              atr_stop_multiplier: 1.0,
              reward_risk_ratio: 2.0
            )

          results << OptimizationResult.new(
            length: length,
            multiplier: multiplier,
            performance_report: report
          )
        end
      end

      results
    end

    private

    def lengths
      (LENGTH_START..LENGTH_END)
    end

    def multipliers
      MULTIPLIER_VARIANTS.times.map do |i|
        (MULTIPLIER_START + (i * MULTIPLIER_STEP)).round(1)
      end
    end
  end
end
