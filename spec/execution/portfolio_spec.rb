# frozen_string_literal: true

require "rails_helper"

RSpec.describe Execution::Portfolio do
  subject(:portfolio) { described_class.new(cash_balance: 10_000.0, leverage: 10) }

  describe "balance and equity updates" do
    it "starts with initial cash balance and 0 PnL" do
      expect(portfolio.cash_balance.to_f).to eq(10_000.0)
      expect(portfolio.equity.to_f).to eq(10_000.0)
      expect(portfolio.unrealized_pnl.to_f).to eq(0.0)
    end

    it "recalculates unrealized PnL when mark price updates" do
      portfolio.add_position("SOLUSDT", :long, 10.0, 100.0)
      expect(portfolio.unrealized_pnl.to_f).to eq(0.0)

      portfolio.update_mark_price!("SOLUSDT", 110.0)
      expect(portfolio.unrealized_pnl.to_f).to eq(100.0)
      expect(portfolio.equity.to_f).to eq(10_100.0)
    end
  end

  describe "serialization and restoration" do
    it "fully restores cash balance and positions from hash" do
      portfolio.add_position("SOLUSDT", :long, 10.0, 100.0)
      portfolio.update_mark_price!("SOLUSDT", 105.0)

      serialized = portfolio.serialize
      restored = described_class.restore(serialized)

      expect(restored.cash_balance.to_f).to eq(10_000.0)
      expect(restored.positions["SOLUSDT"].side).to eq(:long)
      expect(restored.positions["SOLUSDT"].quantity.to_f).to eq(10.0)
      expect(restored.positions["SOLUSDT"].entry_price.to_f).to eq(100.0)
      expect(restored.positions["SOLUSDT"].mark_price.to_f).to eq(105.0)
      expect(restored.positions["SOLUSDT"].unrealized_pnl.to_f).to eq(50.0)
    end
  end
end
