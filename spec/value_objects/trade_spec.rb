# frozen_string_literal: true

require "rails_helper"

RSpec.describe Trade do
  it "calculates long pnl" do
    trade = described_class.new(
      symbol: "SOLUSDT",
      side: :long,
      entry_time: Time.current,
      exit_time: Time.current + 1.hour,
      entry_price: 100,
      exit_price: 110,
      quantity: 1,
      fees: 1,
      reason: "tp"
    )

    expect(trade.pnl).to eq(9)
    expect(trade.winner?).to be(true)
  end
end
