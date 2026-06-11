# frozen_string_literal: true

require "rails_helper"
require_relative "../support/fixture_paths"
require_relative "../support/fixture_loader"

RSpec.describe Research::WalkForwardEngine do
  let(:candles) do
    35.times.map do |i|
      Candle.new(
        open_time: Time.at(i * 3600),
        open: 100.0 + (i % 2 == 0 ? 2.0 : -1.0),
        high: 105.0 + (i % 2 == 0 ? 3.0 : 0.0),
        low: 95.0 - (i % 2 == 0 ? 0.0 : 3.0),
        close: 102.0 + (i % 2 == 0 ? 2.0 : -1.0),
        volume: 1000.0,
        close_time: Time.at((i + 1) * 3600),
        quote_volume: 100000.0,
        trade_count: 50,
        taker_buy_base_volume: 500.0,
        taker_buy_quote_volume: 50000.0
      )
    end
  end

  before do
    stub_const("Research::WalkForwardEngine::OPTIMIZATION_BARS", 20)
    stub_const("Research::WalkForwardEngine::FORWARD_BARS", 5)
    stub_const("Research::WalkForwardEngine::STEP_SIZE", 5)
  end

  describe ".call" do
    subject(:report) { described_class.call(candles: candles) }

    it "returns a WalkForwardReport" do
      expect(report).to be_a(WalkForwardReport)
    end

    it "executes the correct number of iterations" do
      # 35 candles:
      # Max start = 35 - 20 - 5 = 10
      # Starts: 0, 5, 10 -> 3 iterations
      expect(report.total_iterations).to eq(3)
    end

    it "aggregates metrics across iterations" do
      expect(report.total_net_profit).to be_a(Numeric)
      expect(report.average_profit_factor).to be_a(Numeric)
      expect(report.average_win_rate).to be_a(Numeric)
      expect(report.worst_drawdown).to be_a(Numeric)
    end

    it "returns iteration summaries" do
      summary = report.summary
      expect(summary[:total_iterations]).to eq(3)
      expect(summary[:total_net_profit]).to be_a(Numeric)
      expect(summary[:average_profit_factor]).to be_a(Numeric)
      expect(summary[:average_win_rate]).to be_a(Numeric)
      expect(summary[:worst_drawdown]).to be_a(Numeric)
    end
  end
end
