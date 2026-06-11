# frozen_string_literal: true

require "rails_helper"
require_relative "../support/fixture_loader"
require "yaml"

RSpec.describe Research::BacktestRunner do
  let(:candles) { FixtureLoader.load_binance_fixture("SOLUSDT_1h_2025_01.json") }
  let(:snapshot_path) { Rails.root.join("spec/fixtures/snapshots/solusdt_1h_st_10_3.yml") }
  let(:snapshot) { YAML.load_file(snapshot_path) }

  subject(:run_backtest) do
    described_class.call(
      candles: candles,
      period: 10,
      multiplier: 3.0,
      atr_stop_multiplier: 1.0,
      reward_risk_ratio: 2.0
    )
  end

  it "generates correct performance metrics matching the golden snapshot" do
    report = run_backtest

    expect(report.summary).to eq(snapshot)
  end

  it "is deterministic and produces identical results on multiple runs" do
    report1 = run_backtest
    report2 = described_class.call(
      candles: candles,
      period: 10,
      multiplier: 3.0,
      atr_stop_multiplier: 1.0,
      reward_risk_ratio: 2.0
    )

    expect(report1.summary).to eq(report2.summary)
    expect(report1.equity_curve).to eq(report2.equity_curve)
  end

  it "generates trades and equity curve" do
    report = run_backtest

    expect(report.total_trades).to be > 0
    expect(report.trades).not_to be_empty
    expect(report.equity_curve.size).to eq(report.total_trades)
  end
end
