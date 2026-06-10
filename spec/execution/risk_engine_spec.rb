# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/execution/risk_engine"
require_relative "../../app/value_objects/order_request"
require_relative "../../app/value_objects/position_snapshot"

RSpec.describe Execution::RiskEngine do
  let(:engine) do
    described_class.new(
      max_positions: 2,
      max_exposure: 10_000.0,
      daily_loss_limit: 500.0,
      max_consecutive_losses: 3,
      cooldown_period_seconds: 3600,
      max_exchange_errors: 3
    )
  end

  let(:order_request) do
    OrderRequest.new(
      symbol: "SOLUSDT",
      side: :buy,
      quantity: 10.0,
      order_type: :market
    )
  end

  describe "#check!" do
    it "passes when all conditions are met" do
      expect(
        engine.check!(
          order_request: order_request,
          active_positions: [],
          daily_loss: 0.0,
          consecutive_losses: 0,
          exchange_errors: 0
        )
      ).to be(true)
    end

    it "raises RiskError when exchange errors trigger circuit breaker" do
      expect {
        engine.check!(
          order_request: order_request,
          active_positions: [],
          daily_loss: 0.0,
          consecutive_losses: 0,
          exchange_errors: 3
        )
      }.to raise_error(
        Execution::RiskEngine::RiskError,
        /circuit breaker active/
      )
    end

    it "raises RiskError when daily loss limit is exceeded" do
      expect {
        engine.check!(
          order_request: order_request,
          active_positions: [],
          daily_loss: 500.0,
          consecutive_losses: 0,
          exchange_errors: 0
        )
      }.to raise_error(
        Execution::RiskEngine::RiskError,
        /Daily loss limit exceeded/
      )
    end

    it "raises RiskError when consecutive losses trigger cooldown" do
      expect {
        engine.check!(
          order_request: order_request,
          active_positions: [],
          daily_loss: 0.0,
          consecutive_losses: 3,
          last_loss_time: Time.now,
          exchange_errors: 0
        )
      }.to raise_error(
        Execution::RiskEngine::RiskError,
        /cooldown active/
      )
    end

    it "raises RiskError when position count limit is exceeded" do
      active_positions = [
        PositionSnapshot.new(symbol: "BTCUSDT", side: :long, quantity: 1.0, entry_price: 100.0, mark_price: 100.0, unrealized_pnl: 0.0),
        PositionSnapshot.new(symbol: "ETHUSDT", side: :long, quantity: 1.0, entry_price: 100.0, mark_price: 100.0, unrealized_pnl: 0.0)
      ]

      expect {
        engine.check!(
          order_request: order_request,
          active_positions: active_positions,
          daily_loss: 0.0,
          consecutive_losses: 0,
          exchange_errors: 0
        )
      }.to raise_error(
        Execution::RiskEngine::RiskError,
        /Position count limit exceeded/
      )
    end

    it "raises RiskError when exposure limit is exceeded" do
      large_order = OrderRequest.new(
        symbol: "SOLUSDT",
        side: :buy,
        quantity: 200.0,
        order_type: :limit,
        price: 100.0
      )

      expect {
        engine.check!(
          order_request: large_order,
          active_positions: [],
          daily_loss: 0.0,
          consecutive_losses: 0,
          exchange_errors: 0
        )
      }.to raise_error(
        Execution::RiskEngine::RiskError,
        /Exposure limit exceeded/
      )
    end
  end
end
