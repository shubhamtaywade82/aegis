# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/value_objects/order_request"

RSpec.shared_examples "exchange adapter" do
  let(:order_request) do
    OrderRequest.new(
      symbol: "SOLUSDT",
      side: :buy,
      quantity: 10.0,
      order_type: :market
    )
  end

  it "places orders" do
    response = adapter.place_order(order_request)
    expect(response.exchange_order_id).not_to be_nil
    expect(response.status).to eq(:filled)
  end

  it "retrieves positions" do
    pos = adapter.positions
    expect(pos).to be_an(Array)
  end

  it "retrieves balances" do
    acc = adapter.account
    expect(acc[:balance]).to be_a(BigDecimal)
    expect(acc[:available_balance]).to be_a(BigDecimal)
  end

  it "cancels orders" do
    res = adapter.cancel_order(symbol: "SOLUSDT", order_id: "test_order_id")
    expect(res[:status]).to eq(:cancelled)
  end
end
