# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/execution/paper_engine"
require_relative "../../app/value_objects/order_request"

RSpec.describe Execution::PaperEngine do
  subject(:engine) { described_class.new(initial_balance: 10_000.0) }

  describe "#place_order" do
    let(:order_request) do
      OrderRequest.new(
        symbol: "SOLUSDT",
        side: :buy,
        quantity: 10.0,
        order_type: :market
      )
    end

    before do
      engine.set_price("SOLUSDT", 100.0)
    end

    it "executes market buy and creates a position snapshot" do
      response = engine.place_order(order_request)

      expect(response).to be_a(OrderResponse)
      expect(response.status).to eq(:filled)

      # 0.05% taker fee = 10 * 100.0 * 0.0005 = 0.5 fee
      expect(engine.fees_paid.to_f).to eq(0.5)
      expect(engine.balance.to_f).to eq(9_999.5)

      pos = engine.positions.first
      expect(pos).to be_a(PositionSnapshot)
      expect(pos.symbol).to eq("SOLUSDT")
      expect(pos.side).to eq(:long)
      expect(pos.quantity.to_f).to eq(10.0)
    end

    it "realizes profit when closing a long position at a higher price" do
      # 1. Open Long at 100.0
      engine.place_order(order_request)

      # 2. Price moves to 110.0
      engine.set_price("SOLUSDT", 110.0)

      # 3. Sell close position (reduce_only)
      close_request = OrderRequest.new(
        symbol: "SOLUSDT",
        side: :sell,
        quantity: 10.0,
        order_type: :market,
        reduce_only: true
      )

      # Fees for close: 10 * 110.0 * 0.0005 = 0.55 fee
      # Realized Profit: (110 - 100) * 10 = 100.0 profit
      # Final Balance: 10,000.0 - 0.5 (open fee) - 0.55 (close fee) + 100.0 (profit) = 10,098.95
      engine.place_order(close_request)

      expect(engine.positions).to be_empty
      expect(engine.balance.to_f).to eq(10_098.95)
    end
  end

  describe "#drawdown" do
    it "calculates correct drawdown from peak" do
      # Equity is same as balance initially
      expect(engine.drawdown.to_f).to eq(0.0)
    end
  end
end
