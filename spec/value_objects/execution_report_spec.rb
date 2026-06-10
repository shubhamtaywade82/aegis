# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/value_objects/execution_report"

RSpec.describe ExecutionReport do
  subject(:report) do
    described_class.new(
      executed_trades: [],
      gross_net_profit: 100.0,
      execution_net_profit: 80.0,
      fee_impact: 10.0,
      slippage_impact: 8.0,
      funding_impact: 2.0,
      execution_profit_factor: 1.5
    )
  end

  it "calculates correct degradation vs research" do
    expect(report.degradation_vs_research).to eq(20.0)
  end

  it "returns correct summary format" do
    summary = report.summary
    expect(summary[:gross_net_profit]).to eq(100.0)
    expect(summary[:execution_net_profit]).to eq(80.0)
    expect(summary[:degradation_vs_research]).to eq(20.0)
  end
end
