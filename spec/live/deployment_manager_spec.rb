# frozen_string_literal: true

require "rails_helper"

RSpec.describe Live::DeploymentManager do
  let(:order_request) do
    OrderRequest.new(
      symbol: "SOLUSDT",
      side: :buy,
      quantity: 10.0,
      order_type: :market
    )
  end

  it "rejects when live trading is disabled" do
    manager = described_class.new(flags: { live_trading_enabled: false })
    res = manager.process_order(order_request)
    expect(res[:action]).to eq(:reject)
  end

  it "holds order for approval in canary mode when auto_execution is disabled" do
    manager = described_class.new(flags: { live_trading_enabled: true, auto_execution_enabled: false }, stage: :canary)
    res = manager.process_order(order_request)
    expect(res[:action]).to eq(:hold)
    expect(res[:approval_id]).not_to be_nil
  end

  it "executes order when auto_execution is enabled" do
    manager = described_class.new(flags: { live_trading_enabled: true, auto_execution_enabled: true }, stage: :canary)
    res = manager.process_order(order_request)
    expect(res[:action]).to eq(:execute)
  end
end
