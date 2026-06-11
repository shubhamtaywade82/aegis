# frozen_string_literal: true

require "rails_helper"

RSpec.describe Capital::CapitalEngine do
  let(:engine) { described_class.new(exchange_budgets: { binance: 0.60 }, base_risk_pct: 0.005) }

  let(:snapshot) do
    WalletSnapshot.new(
      exchange: :binance,
      wallet_balance: 10_000.0,
      available_balance: 7500.0,
      total_equity: 10_000.0,
      used_margin: 2000.0,
      reserved_margin: 500.0,
      unrealized_pnl: 0.0,
      realized_pnl: 0.0
    )
  end

  it "calculates correct risk budget based on available capital, exchange allocation, and base risk" do
    budget = engine.calculate_risk_budget(
      exchange: :binance,
      wallet_snapshot: snapshot,
      drawdown_pct: 0.0,
      equity_change_pct: 0.0
    )
    expect(budget.to_f).to eq(22.5)
  end

  it "scales down risk budget during drawdown" do
    budget = engine.calculate_risk_budget(
      exchange: :binance,
      wallet_snapshot: snapshot,
      drawdown_pct: 6.0,
      equity_change_pct: 0.0
    )
    expect(budget.to_f).to eq(11.25)
  end
end
