# frozen_string_literal: true

require "rails_helper"

RSpec.describe Portfolio::RebalanceEngine do
  let(:engine) { described_class.new }
  let(:snapshot) do
    PortfolioSnapshot.new(
      cash_balance: 10_000.0,
      equity: 10_000.0,
      used_margin: 1000.0,
      available_margin: 9000.0,
      unrealized_pnl: 0.0,
      realized_pnl: 0.0,
      positions_count: 1,
      positions: {
        "SOLUSDT" => PositionSnapshot.new(
          symbol: "SOLUSDT",
          side: :long,
          quantity: 10.0,
          entry_price: 100.0,
          mark_price: 100.0,
          unrealized_pnl: 0.0
        )
      }
    )
  end

  it "generates buy/sell orders when drift is detected" do
    targets = { "SOLUSDT" => 0.20 }
    orders = engine.generate_orders(snapshot, targets)
    expect(orders.size).to eq(1)
    expect(orders.first[:symbol]).to eq("SOLUSDT")
    expect(orders.first[:side]).to eq(:buy)
    expect(orders.first[:notional].to_f).to eq(1000.0)
  end
end
