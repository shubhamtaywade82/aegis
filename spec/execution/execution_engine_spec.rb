# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/execution/execution_engine"
require_relative "../../app/execution/risk_engine"
require_relative "../../app/execution/paper_engine"
require_relative "../../app/value_objects/order_request"

RSpec.describe Execution::ExecutionEngine do
  let(:adapter) { Execution::PaperEngine.new }
  let(:risk_engine) { Execution::RiskEngine.new(daily_loss_limit: 500.0) }
  subject(:engine) { described_class.new(adapter: adapter, risk_engine: risk_engine) }

  let(:order_request) do
    OrderRequest.new(
      symbol: "SOLUSDT",
      side: :buy,
      quantity: 1.0,
      order_type: :market
    )
  end

  describe "#execute" do
    before do
      # Ensure price is available for SOLUSDT (PaperEngine no longer has mock fallback)
      adapter.set_price("SOLUSDT", BigDecimal("100.0"))
    end

    it "successfully executes an order if risk check passes" do
      response = engine.execute(order_request)
      expect(response).to be_a(OrderResponse)
      expect(response.status).to eq(:filled)
    end

    it "raises RiskError and prevents execution if risk limit is breached" do
      # Breaching daily loss limit
      engine.record_pnl(-600.0)

      expect {
        engine.execute(order_request)
      }.to raise_error(Execution::RiskEngine::RiskError, /Daily loss limit exceeded/)
    end

    it "increments error count if adapter throws an error" do
      allow(adapter).to receive(:place_order).and_raise(StandardError.new("API Down"))

      expect {
        engine.execute(order_request)
      }.to raise_error(StandardError, "API Down")

      expect(engine.exchange_errors).to eq(1)
    end
  end

  describe "#record_pnl" do
    it "updates daily loss and consecutive loss counts on loss" do
      engine.record_pnl(-200.0)
      expect(engine.daily_loss.to_f).to eq(200.0)
      expect(engine.consecutive_losses).to eq(1)

      engine.record_pnl(-100.0)
      expect(engine.daily_loss.to_f).to eq(300.0)
      expect(engine.consecutive_losses).to eq(2)
    end

    it "resets consecutive losses count on profit" do
      engine.record_pnl(-200.0)
      engine.record_pnl(50.0)
      expect(engine.consecutive_losses).to eq(0)
    end
  end
end
