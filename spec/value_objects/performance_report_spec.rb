# frozen_string_literal: true

require "rails_helper"

RSpec.describe PerformanceReport do
  subject(:report) do
    described_class.new(
      total_trades: 20,
      wins: 15,
      losses: 5,
      gross_profit: 75.0,
      gross_loss: 25.0,
      net_profit: 50.0,
      profit_factor: 3.0,
      win_rate: 75.0,
      average_trade: 2.5,
      reward_risk: 1.0,
      max_drawdown: 5.0,
      equity_curve: [ 10.0, 20.0, 30.0, 25.0, 50.0 ],
      trades: []
    )
  end

  it "holds all metrics correctly" do
    expect(report.total_trades).to eq(20)
    expect(report.wins).to eq(15)
    expect(report.losses).to eq(5)
    expect(report.net_profit).to eq(50.0)
  end

  it "is profitable when net profit is positive" do
    expect(report.profitable?).to be(true)
  end

  it "is robust when profit factor > 1.0 and minimum trades and max drawdown constraints are met" do
    expect(report.robust?).to be(true)
  end

  it "supports configurable thresholds for robustness" do
    expect(report.robust?(minimum_trades: 25)).to be(false)
    expect(report.robust?(minimum_profit_factor: 4.0)).to be(false)
    expect(report.robust?(maximum_drawdown: 2.0)).to be(false)
  end

  it "returns a correct summary hash" do
    summary = report.summary
    expect(summary[:net_profit]).to eq(50.0)
    expect(summary[:total_trades]).to eq(20)
  end
end
