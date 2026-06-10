# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/portfolio/allocation_engine"
require_relative "../../app/value_objects/portfolio_snapshot"

RSpec.describe "Correlation Overlay" do
  let(:engine) { Portfolio::AllocationEngine.new }
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

  let(:correlated_assets) do
    [
      { symbol: "BTCUSDT", exchange: :binance, confidence: 90.0, execution_pf: 1.5, persistence: 0.9, atr_pct: 2.0 },
      { symbol: "ETHUSDT", exchange: :binance, confidence: 90.0, execution_pf: 1.5, persistence: 0.9, atr_pct: 2.0 }
    ]
  end

  it "enforces group weights do not exceed group limit (40%)" do
    targets = engine.allocate(assets_metadata: correlated_assets, portfolio_snapshot: snapshot)
    total_group_weight = targets.sum(&:weight)
    expect(total_group_weight).to be <= BigDecimal("0.40")
  end
end
