# frozen_string_literal: true

require "rails_helper"
require "bigdecimal"

RSpec.describe Strategy::OrderGenerator do
  let(:paper_engine) { Execution::PaperEngine.new(initial_balance: 100_000.0) }
  subject(:generator) { described_class.new(paper_engine: paper_engine) }

  describe "#generate_orders" do
    context "when no position exists" do
      it "returns single buy order for bullish signal" do
        orders = generator.generate_orders(
          symbol: "BTCUSDT",
          current_price: BigDecimal("50000.0"),
          new_direction: :bullish,
          current_position: nil
        )

        expect(orders.size).to eq(1)
        order = orders.first
        expect(order.side).to eq(:buy)
        expect(order.order_type).to eq(:market)
        expect(order.reduce_only).to eq(false)
        expect(order.symbol).to eq("BTCUSDT")
        # 30% * 100,000 / 50,000 = 0.6
        expect(order.quantity.to_f).to eq(0.6)
      end

      it "returns single sell order for bearish signal" do
        orders = generator.generate_orders(
          symbol: "ETHUSDT",
          current_price: BigDecimal("3000.0"),
          new_direction: :bearish,
          current_position: nil
        )

        expect(orders.size).to eq(1)
        order = orders.first
        expect(order.side).to eq(:sell)
        expect(order.order_type).to eq(:market)
        expect(order.reduce_only).to eq(false)
        expect(order.symbol).to eq("ETHUSDT")
        # 30% * 100,000 / 3,000 = 10.0
        expect(order.quantity.to_f).to eq(10.0)
      end

      it "qty rounds to 6 decimal places" do
        orders = generator.generate_orders(
          symbol: "BTCUSDT",
          current_price: BigDecimal("33333.333333"),
          new_direction: :bullish,
          current_position: nil
        )

        expect(orders.size).to eq(1)
        # 30,000 / 33333.333333 = 0.900000009, rounded to 6 decimals = 0.9
        expect(orders.first.quantity).to eq(BigDecimal("0.9"))
      end
    end

    context "when flipping position" do
      it "long position + bearish flip returns close and entry sell orders" do
        current_position = { side: :long, quantity: BigDecimal("5.0"), entry_price: BigDecimal("45000.0") }

        orders = generator.generate_orders(
          symbol: "BTCUSDT",
          current_price: BigDecimal("50000.0"),
          new_direction: :bearish,
          current_position: current_position
        )

        expect(orders.size).to eq(2)

        # First order: close long with reduce_only
        close_order = orders[0]
        expect(close_order.side).to eq(:sell)
        expect(close_order.reduce_only).to eq(true)
        expect(close_order.quantity).to eq(BigDecimal("5.0"))
        expect(close_order.order_type).to eq(:market)

        # Second order: new short entry
        entry_order = orders[1]
        expect(entry_order.side).to eq(:sell)
        expect(entry_order.reduce_only).to eq(false)
        expect(entry_order.quantity.to_f).to eq(0.6)
        expect(entry_order.order_type).to eq(:market)
      end

      it "short position + bullish flip returns close and entry buy orders" do
        current_position = { side: :short, quantity: BigDecimal("8.0"), entry_price: BigDecimal("52000.0") }

        orders = generator.generate_orders(
          symbol: "BTCUSDT",
          current_price: BigDecimal("50000.0"),
          new_direction: :bullish,
          current_position: current_position
        )

        expect(orders.size).to eq(2)

        # First order: close short with reduce_only
        close_order = orders[0]
        expect(close_order.side).to eq(:buy)
        expect(close_order.reduce_only).to eq(true)
        expect(close_order.quantity).to eq(BigDecimal("8.0"))
        expect(close_order.order_type).to eq(:market)

        # Second order: new long entry
        entry_order = orders[1]
        expect(entry_order.side).to eq(:buy)
        expect(entry_order.reduce_only).to eq(false)
        expect(entry_order.quantity.to_f).to eq(0.6)
        expect(entry_order.order_type).to eq(:market)
      end
    end

    context "when already aligned" do
      it "returns empty array for long position + bullish" do
        current_position = { side: :long, quantity: BigDecimal("5.0"), entry_price: BigDecimal("49000.0") }

        orders = generator.generate_orders(
          symbol: "BTCUSDT",
          current_price: BigDecimal("50000.0"),
          new_direction: :bullish,
          current_position: current_position
        )

        expect(orders).to be_empty
      end

      it "returns empty array for short position + bearish" do
        current_position = { side: :short, quantity: BigDecimal("5.0"), entry_price: BigDecimal("51000.0") }

        orders = generator.generate_orders(
          symbol: "BTCUSDT",
          current_price: BigDecimal("50000.0"),
          new_direction: :bearish,
          current_position: current_position
        )

        expect(orders).to be_empty
      end
    end

    context "when current_price is invalid" do
      it "returns empty array when current_price is nil" do
        orders = generator.generate_orders(
          symbol: "BTCUSDT",
          current_price: nil,
          new_direction: :bullish,
          current_position: nil
        )

        expect(orders).to be_empty
      end

      it "returns empty array when current_price is 0" do
        orders = generator.generate_orders(
          symbol: "BTCUSDT",
          current_price: BigDecimal("0"),
          new_direction: :bullish,
          current_position: nil
        )

        expect(orders).to be_empty
      end
    end

    context "when qty rounds to 0 due to low balance" do
      it "returns only close order when entry qty is 0" do
        # With an existing long position that needs closing, but qty for new entry rounds to 0
        # balance * 0.30 / 50000 = 0.00002 * 0.30 / 50000 = 0.00000000012 -> rounds to 0
        small_engine = Execution::PaperEngine.new(initial_balance: 0.00002)
        small_generator = described_class.new(paper_engine: small_engine)
        current_position = { side: :long, quantity: BigDecimal("2.0"), entry_price: BigDecimal("45000.0") }

        orders = small_generator.generate_orders(
          symbol: "BTCUSDT",
          current_price: BigDecimal("50000.0"),
          new_direction: :bearish,
          current_position: current_position
        )

        # Should have close order but no entry (qty rounds to 0)
        expect(orders.size).to eq(1)
        expect(orders.first.reduce_only).to eq(true)
      end
    end

    context "with specific price scenarios" do
      it "calculates qty correctly for $10 price with no position" do
        orders = generator.generate_orders(
          symbol: "BTCUSDT",
          current_price: BigDecimal("10.0"),
          new_direction: :bullish,
          current_position: nil
        )

        expect(orders.size).to eq(1)
        # 30% * 100,000 / 10 = 3,000
        expect(orders.first.quantity.to_f).to eq(3000.0)
      end
    end

    context "reduce_only flags" do
      it "close order has reduce_only true, entry has reduce_only false" do
        current_position = { side: :long, quantity: BigDecimal("3.0"), entry_price: BigDecimal("48000.0") }

        orders = generator.generate_orders(
          symbol: "BTCUSDT",
          current_price: BigDecimal("50000.0"),
          new_direction: :bearish,
          current_position: current_position
        )

        expect(orders.size).to eq(2)
        expect(orders[0].reduce_only).to eq(true)
        expect(orders[1].reduce_only).to eq(false)
      end
    end

    context "symbol passthrough" do
      it "OrderRequest symbol matches input symbol" do
        orders = generator.generate_orders(
          symbol: "SOLUSDT",
          current_price: BigDecimal("100.0"),
          new_direction: :bullish,
          current_position: nil
        )

        expect(orders.first.symbol).to eq("SOLUSDT")
      end
    end
  end
end