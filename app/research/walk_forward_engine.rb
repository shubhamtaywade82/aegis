# frozen_string_literal: true

require_relative "optimizer"
require_relative "stable_region_selector"
require_relative "backtest_runner"
require_relative "../value_objects/walk_forward_iteration"
require_relative "../value_objects/walk_forward_report"
require_relative "../value_objects/stable_region"

module Research
  class WalkForwardEngine
    OPTIMIZATION_BARS = 500
    FORWARD_BARS      = 100
    STEP_SIZE         = 100

    def self.call(candles:)
      new(candles: candles).call
    end

    attr_reader :candles

    def initialize(candles:)
      @candles = candles
    end

    def call
      iterations = []

      window_starts.each do |start|
        optimize_from = start
        optimize_to   = start + OPTIMIZATION_BARS - 1

        forward_from  = optimize_to + 1
        forward_to    = forward_from + FORWARD_BARS - 1

        optimization_series =
          candles.slice(
            optimize_from,
            OPTIMIZATION_BARS
          )

        forward_series =
          candles.slice(
            forward_from,
            FORWARD_BARS
          )

        results =
          Research::Optimizer.call(
            candles: optimization_series
          )

        stable_region =
          Research::StableRegionSelector.call(
            optimization_results: results
          )

        if stable_region.nil?
          report = PerformanceReport.new(
            total_trades: 0,
            wins: 0,
            losses: 0,
            gross_profit: 0.0,
            gross_loss: 0.0,
            net_profit: 0.0,
            profit_factor: 0.0,
            win_rate: 0.0,
            average_trade: 0.0,
            reward_risk: 0.0,
            max_drawdown: 0.0,
            equity_curve: [],
            trades: []
          )
          stable_region = StableRegion.new(
            length: 0,
            multiplier: 0.0,
            score: 0.0,
            average_profit_factor: 0.0,
            standard_deviation: 0.0
          )
        else
          report =
            Research::BacktestRunner.call(
              candles: forward_series,
              period: stable_region.length,
              multiplier: stable_region.multiplier,
              atr_stop_multiplier: 1.0,
              reward_risk_ratio: 2.0
            )
        end

        iterations <<
          WalkForwardIteration.new(
            optimization_start: optimize_from,
            optimization_end: optimize_to,
            forward_start: forward_from,
            forward_end: forward_to,
            stable_region: stable_region,
            performance_report: report
          )
      end

      WalkForwardReport.new(
        iterations: iterations
      )
    end

    private

    def window_starts
      starts = []

      max_start =
        candles.size -
        OPTIMIZATION_BARS -
        FORWARD_BARS

      current = 0

      while current <= max_start
        starts << current
        current += STEP_SIZE
      end

      starts
    end
  end
end
