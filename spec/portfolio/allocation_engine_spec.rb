# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/portfolio/allocation_engine"
require_relative "../../app/value_objects/portfolio_snapshot"

RSpec.describe Portfolio::AllocationEngine do
  let(:engine) { described_class.new(max_instrument_weight: 0.8, max_exchange_weight: 1.0) }
  let(:snapshot) do
    PortfolioSnapshot.new(
      cash_balance: 10_000.0,
      equity: 10_000.0,
      used_margin: 0.0,
      available_margin: 10_000.0,
      unrealized_pnl: 0.0,
      realized_pnl: 0.0,
      positions_count: 0
    )
  end

  let(:assets_metadata) do
    [
      { symbol: "BTCUSDT", exchange: :binance, confidence: 90.0, execution_pf: 1.5, persistence: 0.9, atr_pct: 2.0 },
      { symbol: "SOLUSDT", exchange: :binance, confidence: 80.0, execution_pf: 1.4, persistence: 0.8, atr_pct: 3.0 }
    ]
  end

  it "normalizes weights based on target confidence/PF/ATR metrics" do
    targets = engine.allocate(assets_metadata: assets_metadata, portfolio_snapshot: snapshot)
    expect(targets.size).to eq(2)
    expect(targets.first.symbol).to eq("BTCUSDT")
    expect(targets.first.weight).to be > targets.last.weight
  end
end
