# frozen_string_literal: true

require "rails_helper"
require_relative "../../../app/exchanges/binance/order_mapper"
require_relative "../../../app/value_objects/order_request"

RSpec.describe Exchanges::Binance::OrderMapper do
  describe ".to_binance" do
    it "maps limit buy request to correct binance hash structure" do
      req = OrderRequest.new(
        symbol: "SOLUSDT",
        side: :buy,
        quantity: 10.0,
        order_type: :limit,
        price: 100.0,
        reduce_only: true
      )

      mapped = described_class.to_binance(req)

      expect(mapped[:symbol]).to eq("SOLUSDT")
      expect(mapped[:side]).to eq("BUY")
      expect(mapped[:type]).to eq("LIMIT")
      expect(mapped[:quantity]).to eq(10.0)
      expect(mapped[:price]).to eq(100.0)
      expect(mapped[:reduceOnly]).to eq("true")
      expect(mapped[:timeInForce]).to eq("GTC")
    end
  end

  describe ".from_binance" do
    it "maps binance response fields into OrderResponse" do
      resp_hash = {
        "orderId" => 12345,
        "clientOrderId" => "my_id",
        "status" => "FILLED",
        "executedQty" => "10.0",
        "avgPrice" => "100.5"
      }

      mapped = described_class.from_binance(resp_hash)

      expect(mapped).to be_a(OrderResponse)
      expect(mapped.exchange_order_id).to eq("12345")
      expect(mapped.status).to eq(:filled)
      expect(mapped.filled_quantity.to_f).to eq(10.0)
      expect(mapped.average_price.to_f).to eq(100.5)
    end
  end
end
