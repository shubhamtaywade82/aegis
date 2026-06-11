# frozen_string_literal: true

require "rails_helper"

RSpec.describe Research::ExecutionSimulator do
  let(:trade) do
    Trade.new(
      symbol: "SOLUSDT",
      side: :long,
      entry_time: Time.at(0),
      exit_time: Time.at(3600),
      entry_price: 100.0,
      exit_price: 105.0,
      quantity: 10.0,
      fees: 0.0,
      reason: :supertrend_flip
    )
  end

  let(:fee_model) { FeeModel.new(mode: :taker, taker_fee: 0.0005) }
  let(:slippage_model) { SlippageModel.new(bps: 10.0) }
  let(:funding_model) { FundingModel.new(rate: 0.0001) }

  subject(:report) do
    described_class.call(
      trades: [ trade ],
      fee_model: fee_model,
      slippage_model: slippage_model,
      funding_model: funding_model
    )
  end

  it "reduces profitability after costs" do
    expect(report.execution_net_profit).to be < report.research_net_profit
  end

  it "returns ExecutionReport" do
    expect(report).to be_a(ExecutionReport)
  end

  it "calculates execution PF" do
    expect(report.execution_profit_factor).to be_a(Numeric)
  end

  it "calculates degradation" do
    expect(report.degradation_percentage).to be_within(0.01).of(6.35)
  end

  it "flags execution readiness" do
    expect(report.execution_ready?).to be(true)
  end
end
