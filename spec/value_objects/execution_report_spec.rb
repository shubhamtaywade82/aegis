# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/value_objects/execution_report"

RSpec.describe ExecutionReport do
  subject(:report) do
    described_class.new(
      executed_trades: [],
      research_net_profit: 100.0,
      execution_net_profit: 85.0,
      fee_impact: 10.0,
      slippage_impact: 8.0,
      funding_impact: 2.0,
      research_profit_factor: 1.8,
      execution_profit_factor: 1.5
    )
  end

  it "calculates correct degradation percentage" do
    expect(report.degradation_percentage).to eq(15.0)
  end

  it "flags readiness" do
    expect(report.execution_ready?).to be(true)
  end

  it "returns correct summary format" do
    summary = report.summary
    expect(summary[:research_net_profit]).to eq(100.0)
    expect(summary[:execution_net_profit]).to eq(85.0)
    expect(summary[:degradation_percentage]).to eq(15.0)
    expect(summary[:execution_ready]).to be(true)
  end
end
