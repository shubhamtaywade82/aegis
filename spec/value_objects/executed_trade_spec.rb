# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/value_objects/executed_trade"

RSpec.describe ExecutedTrade do
  let(:original_trade) do
    Trade.new(
      symbol: "SOLUSDT",
      side: :long,
      entry_time: Time.at(0),
      exit_time: Time.at(3600),
      entry_price: 100.0,
      exit_price: 105.0,
      quantity: 1.0,
      fees: 0.0,
      reason: :trend_reversal
    )
  end

  subject(:executed) do
    described_class.new(
      trade: original_trade,
      adjusted_entry_price: 100.1,
      adjusted_exit_price: 104.9,
      slippage_cost: 0.2,
      fees: 0.1,
      funding_cost: 0.0
    )
  end

  it "holds correct attributes" do
    expect(executed.trade).to eq(original_trade)
    expect(executed.adjusted_entry_price).to eq(100.1)
    expect(executed.adjusted_exit_price).to eq(104.9)
    expect(executed.fees).to eq(0.1)
    expect(executed.funding_cost).to eq(0.0)
    expect(executed.slippage_cost).to eq(0.2)
  end

  it "calculates execution_pnl correctly" do
    # gross = (104.9 - 100.1) * 1.0 = 4.8
    # execution_pnl = 4.8 - 0.1 - 0.0 = 4.7
    expect(executed.execution_pnl.to_f).to eq(4.7)
  end
end
