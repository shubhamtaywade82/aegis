# frozen_string_literal: true

require "rails_helper"

RSpec.describe Execution::RiskEngine do
  let(:engine) do
    described_class.new(
      max_positions: 3,
      max_exposure: 0.50, # 50% of equity
      max_leverage: 5,
      daily_loss_limit: 0.03, # 3% of equity
      max_consecutive_losses: 3,
      cooldown_period_seconds: 14_400, # 4 hours
      max_trades_per_day: 20,
      max_rest_failures: 5,
      max_ws_outage_seconds: 60,
      max_clock_drift_ms: 500,
      max_correlated_positions: 2
    )
  end

  let(:portfolio) { Execution::Portfolio.new(cash_balance: 10_000.0, leverage: 5) }

  let(:order_request) do
    OrderRequest.new(
      symbol: "SOLUSDT",
      side: :buy,
      quantity: 10.0,
      order_type: :market
    )
  end

  describe "#validate_order!" do
    context "when all conditions are met" do
      it "approves the order request" do
        decision = engine.validate_order!(
          order_request: order_request,
          portfolio: portfolio,
          market_context: { mark_price: BigDecimal("10.0") }
        )
        expect(decision).to be_approved
        expect(decision.reasons).to be_empty
        expect(decision.severity).to eq(:none)
      end
    end

    context "Level 1: Position Risk" do
      it "rejects when position limit is exceeded (4th position)" do
        # Fill 3 positions
        portfolio.add_position("BTCUSDT", :long, 1.0, 100.0)
        portfolio.add_position("ETHUSDT", :long, 1.0, 100.0)
        portfolio.add_position("ADAUSDT", :long, 1.0, 100.0)

        # Place a 4th new position order
        decision = engine.validate_order!(
          order_request: order_request,
          portfolio: portfolio,
          market_context: { mark_price: BigDecimal("10.0") }
        )
        expect(decision).not_to be_approved
        expect(decision.reasons).to include(/Position count limit exceeded/)
        expect(decision.severity).to eq(:high)
      end

      it "rejects when leverage limit is exceeded" do
        portfolio.leverage = 6
        decision = engine.validate_order!(
          order_request: order_request,
          portfolio: portfolio,
          market_context: { mark_price: BigDecimal("10.0") }
        )
        expect(decision).not_to be_approved
        expect(decision.reasons).to include(/Leverage limit exceeded/)
        expect(decision.severity).to eq(:critical)
      end

      it "rejects when risk per trade is too high (> 0.5% equity)" do
        # Entry = 100, Stop = 90 (Stop distance = 10). Qty = 6. Equity = 10,000.
        # Risk = 10 * 6 = 60. 60 / 10,000 = 0.006 (0.6% > 0.5%)
        risky_order = OrderRequest.new(
          symbol: "SOLUSDT",
          side: :buy,
          quantity: 6.0,
          order_type: :limit,
          price: 100.0
        )
        decision = engine.validate_order!(
          order_request: risky_order,
          portfolio: portfolio,
          market_context: { stop_price: BigDecimal("90.0") }
        )
        expect(decision).not_to be_approved
        expect(decision.reasons).to include(/Risk per trade limit exceeded/)
        expect(decision.severity).to eq(:high)
      end
    end

    context "Level 2: Portfolio Risk" do
      it "rejects when maximum exposure is exceeded (> 50% equity)" do
        # Equity = 10,000. Max exposure = 5,000.
        # Current exposure = 4,000.
        portfolio.add_position("BTCUSDT", :long, 40.0, 100.0)
        # Order exposure = 15.0 * 100.0 = 1,500. Total potential = 5,500 > 5,000.
        large_order = OrderRequest.new(
          symbol: "SOLUSDT",
          side: :buy,
          quantity: 15.0,
          order_type: :limit,
          price: 100.0
        )
        decision = engine.validate_order!(
          order_request: large_order,
          portfolio: portfolio
        )
        expect(decision).not_to be_approved
        expect(decision.reasons).to include(/Exposure limit exceeded/)
        expect(decision.severity).to eq(:high)
      end

      it "rejects when correlation limits are exceeded (max 2 positions per group)" do
        # Group L2: SOL, AVAX, ADA
        portfolio.add_position("SOLUSDT", :long, 1.0, 10.0)
        portfolio.add_position("AVAXUSDT", :long, 1.0, 10.0)

        # Attempt to buy ADA
        ada_order = OrderRequest.new(
          symbol: "ADAUSDT",
          side: :buy,
          quantity: 10.0,
          order_type: :market
        )
        decision = engine.validate_order!(
          order_request: ada_order,
          portfolio: portfolio,
          market_context: { mark_price: BigDecimal("1.0") }
        )
        expect(decision).not_to be_approved
        expect(decision.reasons).to include(/Correlation limit exceeded/)
        expect(decision.severity).to eq(:medium)
      end
    end

    context "Level 3: Daily Risk" do
      it "rejects when daily loss limit is exceeded (> 3% of equity)" do
        decision = engine.validate_order!(
          order_request: order_request,
          portfolio: portfolio,
          market_context: { daily_loss: BigDecimal("301.0") }
        )
        expect(decision).not_to be_approved
        expect(decision.reasons).to include(/Daily loss limit exceeded/)
        expect(decision.severity).to eq(:critical)
      end

      it "rejects when consecutive loss cooldown is active" do
        decision = engine.validate_order!(
          order_request: order_request,
          portfolio: portfolio,
          market_context: {
            consecutive_losses: 3,
            last_loss_time: Time.now - 3600
          }
        )
        expect(decision).not_to be_approved
        expect(decision.reasons).to include(/Risk cooldown active/)
        expect(decision.severity).to eq(:high)
      end

      it "rejects when daily trade limit is exceeded" do
        decision = engine.validate_order!(
          order_request: order_request,
          portfolio: portfolio,
          market_context: { daily_trades_count: 20 }
        )
        expect(decision).not_to be_approved
        expect(decision.reasons).to include(/Daily trade limit exceeded/)
        expect(decision.severity).to eq(:high)
      end
    end

    context "Level 4: Infrastructure Risk" do
      it "rejects when REST failure breaker triggers" do
        decision = engine.validate_order!(
          order_request: order_request,
          portfolio: portfolio,
          market_context: { rest_failures: 5 }
        )
        expect(decision).not_to be_approved
        expect(decision.reasons).to include(/REST failure|circuit breaker active/)
        expect(decision.severity).to eq(:critical)
      end

      it "rejects when WebSocket outage breaker triggers" do
        decision = engine.validate_order!(
          order_request: order_request,
          portfolio: portfolio,
          market_context: { websocket_disconnected_seconds: 61 }
        )
        expect(decision).not_to be_approved
        expect(decision.reasons).to include(/WebSocket outage limit exceeded/)
        expect(decision.severity).to eq(:critical)
      end

      it "rejects when reconciliation mismatch occurs" do
        decision = engine.validate_order!(
          order_request: order_request,
          portfolio: portfolio,
          market_context: { reconciliation_failed: true }
        )
        expect(decision).not_to be_approved
        expect(decision.reasons).to include(/Reconciliation mismatch detected/)
        expect(decision.severity).to eq(:critical)
      end

      it "rejects when clock drift is too large" do
        decision = engine.validate_order!(
          order_request: order_request,
          portfolio: portfolio,
          market_context: { clock_drift_ms: 501 }
        )
        expect(decision).not_to be_approved
        expect(decision.reasons).to include(/Clock drift limit exceeded/)
        expect(decision.severity).to eq(:high)
      end
    end

    context "Level 5: Emergency Controls" do
      it "rejects when kill switch is activated" do
        decision = engine.validate_order!(
          order_request: order_request,
          portfolio: portfolio,
          market_context: { kill_switch_active: true }
        )
        expect(decision).not_to be_approved
        expect(decision.reasons).to include(/Kill switch active/)
        expect(decision.severity).to eq(:critical)
      end

      it "rejects when panic flatten is active" do
        decision = engine.validate_order!(
          order_request: order_request,
          portfolio: portfolio,
          market_context: { panic_flatten_active: true }
        )
        expect(decision).not_to be_approved
        expect(decision.reasons).to include(/Panic flatten active/)
        expect(decision.severity).to eq(:critical)
      end
    end
  end

  describe "#check!" do
    it "raises RiskError when a validation fails" do
      expect {
        engine.check!(
          order_request: order_request,
          active_positions: [],
          daily_loss: 0.0,
          consecutive_losses: 3,
          last_loss_time: Time.now,
          exchange_errors: 0
        )
      }.to raise_error(Execution::RiskEngine::RiskError, /Risk cooldown active/)
    end
  end
end
