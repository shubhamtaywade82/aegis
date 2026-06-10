# frozen_string_literal: true

require "rails_helper"

RSpec.describe PerformanceReport do
  subject(:report) do
    described_class.new(
      trades: Array.new(20) {
        Trade.new(
          symbol: "SOLUSDT", side: :long, entry_time: Time.current, exit_time: Time.current,
          entry_price: 100, exit_price: 105, quantity: 1, fees: 0, reason: "tp"
        )
      },
      wins: 15,
      losses: 5,
      gross_profit: 75.0,
      gross_loss: 25.0,
      net_profit: 50.0,
      profit_factor: 3.0,
      win_rate: 75.0,
      average_trade: 2.5,
      reward_risk: 1.0,
      max_drawdown: 5.0
    )
  end

  it "holds all metrics correctly" do
    expect(report.wins).to eq(15)
    expect(report.losses).to eq(5)
    expect(report.net_profit).to eq(50.0)
  end

  it "is profitable when net profit is positive" do
    expect(report.profitable?).to be(true)
  end

  it "is robust when profit factor > 1.0 and minimum trades are met" do
    expect(report.robust?).to be(true)
  end

  it "returns a correct summary hash" do
    summary = report.summary
    expect(summary[:net_profit]).to eq(50.0)
    expect(summary[:trade_count]).to eq(20)
  end
end
