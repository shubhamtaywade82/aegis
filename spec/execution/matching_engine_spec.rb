# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/execution/matching_engine"
require_relative "../../app/value_objects/order_request"
require_relative "../../app/value_objects/slippage_model"

RSpec.describe Execution::MatchingEngine do
  let(:candle) do
    Candle.new(
      open_time: Time.now,
      open: 100.0,
      high: 105.0,
      low: 95.0,
      close: 102.0,
      volume: 1000.0,
      close_time: Time.now,
      quote_volume: 100000.0,
      trade_count: 50,
      taker_buy_base_volume: 500.0,
      taker_buy_quote_volume: 50000.0
    )
  end

  let(:slippage_model) { SlippageModel.new(bps: 0.0) }

  describe ".match" do
    it "matches limit buy when low <= limit price" do
      order = OrderRequest.new(
        symbol: "SOLUSDT",
        side: :buy,
        quantity: 10.0,
        order_type: :limit,
        price: 98.0
      )

      fills = described_class.match(
        open_orders: [ order ],
        candle: candle,
        latest_price: 100.0,
        slippage_model: slippage_model,
        symbol: "SOLUSDT"
      )

      expect(fills.size).to eq(1)
      expect(fills.first.price.to_f).to eq(98.0)
    end

    it "does not match limit buy when low > limit price" do
      order = OrderRequest.new(
        symbol: "SOLUSDT",
        side: :buy,
        quantity: 10.0,
        order_type: :limit,
        price: 90.0
      )

      fills = described_class.match(
        open_orders: [ order ],
        candle: candle,
        latest_price: 100.0,
        slippage_model: slippage_model,
        symbol: "SOLUSDT"
      )

      expect(fills).to be_empty
    end
  end
end
