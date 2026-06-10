# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/research/metrics_calculator"

RSpec.describe Research::MetricsCalculator do
  let(:trades) do
    [
      Trade.new(
        symbol: "BTCUSDT",
        side: :long,
        entry_time: Time.current - 2.hours,
        exit_time: Time.current - 1.hour,
        entry_price: 100,
        exit_price: 110,
        quantity: 1.0,
        fees: 0.0,
        reason: "tp"
      ),
      Trade.new(
        symbol: "BTCUSDT",
        side: :short,
        entry_time: Time.current - 1.hour,
        exit_time: Time.current,
        entry_price: 100,
        exit_price: 105,
        quantity: 1.0,
        fees: 0.0,
        reason: "sl"
      )
    ]
  end

  it "calculates correct performance metrics" do
    report = described_class.calculate(trades)

    expect(report.trades.size).to eq(2)
    expect(report.wins).to eq(1)
    expect(report.losses).to eq(1)
    expect(report.gross_profit).to eq(10.0)
    expect(report.gross_loss).to eq(5.0)
    expect(report.net_profit).to eq(5.0)
    expect(report.profit_factor).to eq(2.0)
    expect(report.win_rate).to eq(50.0)
    expect(report.average_trade).to eq(2.5)
    expect(report.reward_risk).to eq(2.0)
    expect(report.max_drawdown).to eq(5.0)
  end

  it "handles empty trades list" do
    report = described_class.calculate([])

    expect(report.net_profit).to eq(0.0)
    expect(report.win_rate).to eq(0.0)
  end
end
