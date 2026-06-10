# frozen_string_literal: true

require "rails_helper"

RSpec.describe OptimizationResult do
  it "builds summaries" do
    params = ParameterSet.new(
      length: 10,
      multiplier: 2.0,
      stable_score: 1.5,
      profit_factor: 1.8,
      trade_count: 25
    )

    result = described_class.new(
      symbol: "SOLUSDT",
      interval: "1h",
      optimize_from: 0,
      optimize_to: 499,
      forward_from: 500,
      forward_to: 599,
      parameter_set: params,
      net_profit: 1500,
      profit_factor: 1.6,
      win_rate: 55.0,
      trade_count: 18,
      max_drawdown: 4.2
    )

    expect(result.profitable?).to be(true)
    expect(result.robust?).to be(true)
    expect(result.summary[:symbol]).to eq("SOLUSDT")
  end
end
