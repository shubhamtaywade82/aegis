# frozen_string_literal: true

require "rails_helper"
require "bigdecimal"

RSpec.describe Strategy::SupertrendStrategy do
  let(:redis) { MarketDataFeed.redis }
  let(:paper_engine) { Execution::PaperEngine.new(initial_balance: 100_000.0) }
  let(:risk_engine) { Execution::RiskEngine.new(max_positions: 3, max_exposure: 0.50) }
  let(:execution_engine) { Execution::ExecutionEngine.new(adapter: paper_engine, risk_engine: risk_engine) }
  let(:signal_monitor) { Strategy::SignalMonitor.new(redis: redis) }
  let(:position_tracker) { Strategy::PositionTracker.new(redis: redis) }
  let(:order_generator) { Strategy::OrderGenerator.new(paper_engine: paper_engine) }

  subject(:strategy) do
    Strategy::SupertrendStrategy.new(
      symbols: %w[BTCUSDT ETHUSDT],
      paper_engine: paper_engine,
      execution_engine: execution_engine,
      signal_monitor: signal_monitor,
      position_tracker: position_tracker,
      order_generator: order_generator
    )
  end

  before { redis.flushdb }
  after  { redis.flushdb }

  describe "#evaluate_symbol" do
    context "when no flip (same direction)" do
      it "does not execute any orders" do
        # Store previous direction as bullish
        redis.set("strategy:supertrend:last_direction:BTCUSDT", "bullish")
        # Set current supertrend to also be bullish (no flip)
        redis.set("trading:supertrend:BTCUSDT", '{"direction":"BULLISH","value":123.45}')
        # Set ticker price
        redis.set("trading:ticks:BTCUSDT", '{"c":"50000.00"}')

        strategy.evaluate_symbol("BTCUSDT")

        expect(paper_engine.trades_history).to be_empty
      end
    end

    context "when first observation (no previous direction stored)" do
      it "does not execute any orders (first observation stores direction but does not flip)" do
        # No stored previous direction
        redis.set("trading:supertrend:BTCUSDT", '{"direction":"BULLISH","value":123.45}')
        redis.set("trading:ticks:BTCUSDT", '{"c":"50000.00"}')

        strategy.evaluate_symbol("BTCUSDT")

        expect(paper_engine.trades_history).to be_empty
        # Direction should be stored for next check
        expect(redis.get("strategy:supertrend:last_direction:BTCUSDT")).to eq("bullish")
      end
    end

    context "when flip with no existing position" do
      it "opens a long position on bullish flip" do
        # Store previous direction as bearish
        redis.set("strategy:supertrend:last_direction:BTCUSDT", "bearish")
        # Set current supertrend to bullish
        redis.set("trading:supertrend:BTCUSDT", '{"direction":"BULLISH","value":123.45}')
        # Set ticker price
        redis.set("trading:ticks:BTCUSDT", '{"c":"50000.00"}')

        strategy.evaluate_symbol("BTCUSDT")

        # Paper engine should have a long position
        positions = paper_engine.positions
        expect(positions.size).to eq(1)
        expect(positions.first.symbol).to eq("BTCUSDT")
        expect(positions.first.side).to eq(:long)

        # Position tracker should show long
        tracker_pos = position_tracker.current_position("BTCUSDT")
        expect(tracker_pos).not_to be_nil
        expect(tracker_pos[:side]).to eq(:long)

        # Trade history should have 1 entry
        expect(paper_engine.trades_history.size).to eq(1)
      end
    end

    context "when flip with opposing position" do
      it "closes long and opens short on bearish flip" do
        # First, seed a long position directly via paper_engine
        paper_engine.set_price("BTCUSDT", BigDecimal("50000.0"))
        # Manually seed position to avoid adding to trades_history
        paper_engine.positions_list << PositionSnapshot.new(
          symbol: "BTCUSDT",
          side: :long,
          quantity: BigDecimal("0.5"),
          entry_price: BigDecimal("50000.0"),
          mark_price: BigDecimal("50000.0"),
          unrealized_pnl: BigDecimal("0.0")
        )
        # Sync tracker with long position
        position_tracker.set_position(
          "BTCUSDT",
          side: :long,
          quantity: BigDecimal("0.5"),
          entry_price: BigDecimal("50000.0")
        )

        # Store signal direction as bullish (opposing to upcoming bearish flip)
        redis.set("strategy:supertrend:last_direction:BTCUSDT", "bullish")

        # Now set supertrend to bearish (flip!)
        redis.set("trading:supertrend:BTCUSDT", '{"direction":"BEARISH","value":120.00}')
        redis.set("trading:ticks:BTCUSDT", '{"c":"51000.00"}')

        trades_before = paper_engine.trades_history.size
        strategy.evaluate_symbol("BTCUSDT")

        # Paper engine should now have short position
        positions = paper_engine.positions
        expect(positions.size).to eq(1)
        expect(positions.first.side).to eq(:short)

        # Position tracker should show short
        tracker_pos = position_tracker.current_position("BTCUSDT")
        expect(tracker_pos).not_to be_nil
        expect(tracker_pos[:side]).to eq(:short)

        # Trade history should have 2 entries (close long + entry short) added by evaluate_symbol
        expect(paper_engine.trades_history.size - trades_before).to eq(2)
      end
    end

    context "when price unavailable" do
      it "does not execute any orders" do
        # No ticker in Redis
        # Set a flip condition
        redis.set("strategy:supertrend:last_direction:BTCUSDT", "bearish")
        redis.set("trading:supertrend:BTCUSDT", '{"direction":"BULLISH","value":123.45}')

        strategy.evaluate_symbol("BTCUSDT")

        expect(paper_engine.trades_history).to be_empty
      end
    end

    context "when RiskError on first order" do
      it "logs warning and does not raise, position remains" do
        # Seed a long position and tracker
        paper_engine.set_price("BTCUSDT", BigDecimal("50000.0"))
        buy_order = OrderRequest.new(
          symbol: "BTCUSDT",
          side: :buy,
          quantity: BigDecimal("0.5"),
          order_type: :market,
          reduce_only: false
        )
        execution_engine.execute(buy_order)
        position_tracker.set_position(
          "BTCUSDT",
          side: :long,
          quantity: BigDecimal("0.5"),
          entry_price: BigDecimal("50000.0")
        )

        # Store signal direction as bullish
        redis.set("strategy:supertrend:last_direction:BTCUSDT", "bullish")
        # Set flip to bearish
        redis.set("trading:supertrend:BTCUSDT", '{"direction":"BEARISH","value":120.00}')
        redis.set("trading:ticks:BTCUSDT", '{"c":"51000.00"}')

        # Stub execution_engine.execute to raise RiskError
        allow(execution_engine).to receive(:execute).and_raise(Execution::RiskEngine::RiskError.new("test"))

        expect(Rails.logger).to receive(:warn).with(/\[SupertrendStrategy\] BTCUSDT: Risk check failed -> test/)

        strategy.evaluate_symbol("BTCUSDT")

        # Position tracker should still show long (sync wasn't called after failed order)
        tracker_pos = position_tracker.current_position("BTCUSDT")
        expect(tracker_pos).not_to be_nil
        expect(tracker_pos[:side]).to eq(:long)
      end
    end

    context "when StandardError on first order" do
      it "logs error and does not raise, position remains" do
        # Seed a long position and tracker
        paper_engine.set_price("BTCUSDT", BigDecimal("50000.0"))
        buy_order = OrderRequest.new(
          symbol: "BTCUSDT",
          side: :buy,
          quantity: BigDecimal("0.5"),
          order_type: :market,
          reduce_only: false
        )
        execution_engine.execute(buy_order)
        position_tracker.set_position(
          "BTCUSDT",
          side: :long,
          quantity: BigDecimal("0.5"),
          entry_price: BigDecimal("50000.0")
        )

        # Store signal direction as bullish
        redis.set("strategy:supertrend:last_direction:BTCUSDT", "bullish")
        # Set flip to bearish
        redis.set("trading:supertrend:BTCUSDT", '{"direction":"BEARISH","value":120.00}')
        redis.set("trading:ticks:BTCUSDT", '{"c":"51000.00"}')

        # Stub execution_engine.execute to raise StandardError
        allow(execution_engine).to receive(:execute).and_raise(StandardError.new("test"))

        expect(Rails.logger).to receive(:error).with(/\[SupertrendStrategy\] BTCUSDT: Order execution error -> StandardError: test/)

        strategy.evaluate_symbol("BTCUSDT")

        # Position tracker should still show long (sync wasn't called after failed order)
        tracker_pos = position_tracker.current_position("BTCUSDT")
        expect(tracker_pos).not_to be_nil
        expect(tracker_pos[:side]).to eq(:long)
      end
    end
  end

  describe "#execute" do
    context "when iterating all symbols" do
      it "calls evaluate_symbol for each symbol" do
        # Set up BTCUSDT with flip
        redis.set("strategy:supertrend:last_direction:BTCUSDT", "bearish")
        redis.set("trading:supertrend:BTCUSDT", '{"direction":"BULLISH","value":123.45}')
        redis.set("trading:ticks:BTCUSDT", '{"c":"50000.00"}')

        # Set up ETHUSDT with flip
        redis.set("strategy:supertrend:last_direction:ETHUSDT", "bearish")
        redis.set("trading:supertrend:ETHUSDT", '{"direction":"BULLISH","value":3000.00}')
        redis.set("trading:ticks:ETHUSDT", '{"c":"3000.00"}')

        expect(strategy).to receive(:evaluate_symbol).with("BTCUSDT").once
        expect(strategy).to receive(:evaluate_symbol).with("ETHUSDT").once

        strategy.execute
      end
    end
  end

  describe "position cleared after close" do
    it "clears position when qty rounds to 0" do
      # Create paper engine with very small balance so entry qty rounds to 0
      tiny_paper_engine = Execution::PaperEngine.new(initial_balance: 0.001)
      tiny_execution_engine = Execution::ExecutionEngine.new(adapter: tiny_paper_engine, risk_engine: risk_engine)
      tiny_order_generator = Strategy::OrderGenerator.new(paper_engine: tiny_paper_engine)

      tiny_strategy = Strategy::SupertrendStrategy.new(
        symbols: %w[BTCUSDT],
        paper_engine: tiny_paper_engine,
        execution_engine: tiny_execution_engine,
        signal_monitor: signal_monitor,
        position_tracker: position_tracker,
        order_generator: tiny_order_generator
      )

      # Seed long position directly
      tiny_paper_engine.set_price("BTCUSDT", BigDecimal("50000.0"))
      tiny_paper_engine.positions_list << PositionSnapshot.new(
        symbol: "BTCUSDT",
        side: :long,
        quantity: BigDecimal("0.5"),
        entry_price: BigDecimal("50000.0"),
        mark_price: BigDecimal("50000.0"),
        unrealized_pnl: BigDecimal("0.0")
      )
      position_tracker.set_position(
        "BTCUSDT",
        side: :long,
        quantity: BigDecimal("0.5"),
        entry_price: BigDecimal("50000.0")
      )

      # Set flip to bearish with price high enough that entry qty rounds to 0
      redis.set("strategy:supertrend:last_direction:BTCUSDT", "bullish")
      redis.set("trading:supertrend:BTCUSDT", '{"direction":"BEARISH","value":120.00}')
      redis.set("trading:ticks:BTCUSDT", '{"c":"50000.00"}')

      tiny_strategy.evaluate_symbol("BTCUSDT")

      # Paper engine should have no position (long closed, new short qty rounds to 0)
      expect(tiny_paper_engine.positions).to be_empty

      # Position tracker should return nil
      expect(position_tracker.current_position("BTCUSDT")).to be_nil
    end
  end
end