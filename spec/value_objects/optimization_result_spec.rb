# frozen_string_literal: true

require "rails_helper"

RSpec.describe OptimizationResult do
  let(:report) do
    PerformanceReport.new(
      total_trades: 25,
      wins: 15,
      losses: 10,
      gross_profit: 20,
      gross_loss: 10,
      net_profit: 10,
      profit_factor: 2.0,
      win_rate: 60.0,
      average_trade: 0.4,
      reward_risk: 1.5,
      max_drawdown: 5.0,
      equity_curve: [],
      trades: []
    )
  end

  subject(:result) do
    described_class.new(
      length: 10,
      multiplier: 1.5,
      performance_report: report
    )
  end

  it "delegates metrics" do
    expect(result.profit_factor).to eq(2.0)
    expect(result.win_rate).to eq(60.0)
  end

  it "validates trade count" do
    expect(result.valid?).to be(true)
  end

  it "returns summary" do
    expect(result.summary[:length]).to eq(10)
    expect(result.summary[:multiplier]).to eq(1.5)
  end
end
