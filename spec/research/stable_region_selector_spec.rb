# frozen_string_literal: true

require "rails_helper"

RSpec.describe Research::StableRegionSelector do
  describe ".call" do
    let(:report) do
      PerformanceReport.new(
        total_trades: 30,
        wins: 18,
        losses: 12,
        gross_profit: 30,
        gross_loss: 15,
        net_profit: 15,
        profit_factor: 1.5,
        win_rate: 60,
        average_trade: 0.5,
        reward_risk: 1.2,
        max_drawdown: 5,
        equity_curve: [],
        trades: []
      )
    end

    let(:results) do
      (5..14).flat_map do |length|
        (0..9).map do |m|
          OptimizationResult.new(
            length: length,
            multiplier: (1.0 + (m * 0.1)).round(1),
            performance_report: report
          )
        end
      end
    end

    it "returns a StableRegion" do
      region =
        described_class.call(
          optimization_results: results
        )

      expect(region)
        .to be_a(StableRegion)
    end

    it "returns valid parameters" do
      region =
        described_class.call(
          optimization_results: results
        )

      expect(region.length)
        .to be_between(6, 13)

      expect(region.multiplier)
        .to be_between(1.1, 1.8)
    end
  end
end
