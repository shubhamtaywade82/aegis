# frozen_string_literal: true

require "rails_helper"

RSpec.describe Position do
  it "calculates unrealized pnl" do
    position = described_class.new(
      symbol: "SOLUSDT",
      side: :long,
      entry_time: Time.current,
      entry_price: 100,
      quantity: 1,
      stop_loss: 95,
      take_profit: 110,
      trail_stop: 97
    )

    expect(position.unrealized_pnl(105)).to eq(5)
    expect(position.reward_risk_ratio).to eq(2)
  end
end
