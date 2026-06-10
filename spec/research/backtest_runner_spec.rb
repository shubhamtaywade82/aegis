# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/research/backtest_runner"
require_relative "../support/fixture_loader"
require "yaml"

RSpec.describe Research::BacktestRunner do
  let(:candles) { FixtureLoader.load_binance_fixture("SOLUSDT_1h_2025_01.json") }

  it "runs successfully and prints summary" do
    report = described_class.call(
      candles: candles,
      period: 10,
      multiplier: 3.0,
      atr_stop_multiplier: 1.0,
      reward_risk_ratio: 2.0
    )

    puts "SUMMARY_START"
    puts report.summary.to_yaml
    puts "SUMMARY_END"
  end
end
