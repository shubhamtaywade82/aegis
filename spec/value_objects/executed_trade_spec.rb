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
      original_trade: original_trade,
      executed_entry_price: 100.1,
      executed_exit_price: 104.9,
      slippage_cost: 0.2,
      fee_cost: 0.1,
      funding_cost: 0.0,
      executed_pnl: 4.5
    )
  end

  it "delegates attributes to the original trade" do
    expect(executed.symbol).to eq("SOLUSDT")
    expect(executed.side).to eq(:long)
    expect(executed.quantity).to eq(1.0)
    expect(executed.entry_time).to eq(Time.at(0))
  end

  it "properly reports winner/loser status" do
    expect(executed.winner?).to be(true)
    expect(executed.loser?).to be(false)
  end

  it "reports loser status when net profit is negative" do
    losing_executed = described_class.new(
      original_trade: original_trade,
      executed_entry_price: 100.1,
      executed_exit_price: 99.0,
      slippage_cost: 0.2,
      fee_cost: 0.1,
      funding_cost: 0.0,
      executed_pnl: -1.4
    )
    expect(losing_executed.winner?).to be(false)
    expect(losing_executed.loser?).to be(true)
  end
end
