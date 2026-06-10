# frozen_string_literal: true

require "rails_helper"
require_relative "../../../app/exchanges/binance/position_mapper"

RSpec.describe Exchanges::Binance::PositionMapper do
  describe ".from_binance" do
    it "maps binance position array attributes correctly" do
      pos_hash = {
        "symbol" => "SOLUSDT",
        "positionAmt" => "10.5",
        "entryPrice" => "100.2",
        "markPrice" => "102.5",
        "unRealizedProfit" => "24.15"
      }

      mapped = described_class.from_binance(pos_hash)

      expect(mapped).to be_a(PositionSnapshot)
      expect(mapped.symbol).to eq("SOLUSDT")
      expect(mapped.side).to eq(:long)
      expect(mapped.quantity.to_f).to eq(10.5)
      expect(mapped.entry_price.to_f).to eq(100.2)
      expect(mapped.mark_price.to_f).to eq(102.5)
      expect(mapped.unrealized_pnl.to_f).to eq(24.15)
    end
  end
end
