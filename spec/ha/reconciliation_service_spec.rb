# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/ha/reconciliation_service"
require_relative "../../app/exchanges/base_adapter"
require_relative "../../app/execution/portfolio"

RSpec.describe Ha::ReconciliationService do
  let(:adapter) { double }
  let(:portfolio) { Execution::Portfolio.new(cash_balance: 10_000.0, leverage: 5) }
  let(:service) { described_class.new(exchange_adapter: adapter, database_portfolio: portfolio) }

  it "passes when balances and positions reconcile" do
    allow(adapter).to receive(:account).and_return({ balance: 10_000.0 })
    allow(adapter).to receive(:positions).and_return([])

    expect(service.reconcile!).to be(true)
    expect(service.mismatches).to be_empty
  end

  it "fails and lists mismatch when balances do not reconcile" do
    allow(adapter).to receive(:account).and_return({ balance: 9500.0 })
    allow(adapter).to receive(:positions).and_return([])

    expect(service.reconcile!).to be(false)
    expect(service.mismatches.first).to include("Balance mismatch")
  end
end
