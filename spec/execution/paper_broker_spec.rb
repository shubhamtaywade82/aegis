# frozen_string_literal: true

require "rails_helper"

RSpec.describe Execution::PaperBroker do
  let(:portfolio) { Execution::Portfolio.new(cash_balance: 10_000.0) }
  let(:event_store) { Execution::EventStore.new }
  let(:slippage_model) { SlippageModel.new(bps: 10.0) }
  subject(:broker) do
    described_class.new(
      portfolio: portfolio,
      event_store: event_store,
      slippage_model: slippage_model
    )
  end

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

  describe "order flow" do
    it "submits, matches, and updates cash/positions correctly" do
      order = OrderRequest.new(
        symbol: "SOLUSDT",
        side: :buy,
        quantity: 10.0,
        order_type: :market
      )
      broker.submit_order(order)
      expect(broker.open_orders.size).to eq(1)

      broker.process_candle(candle, 100.0, "SOLUSDT")

      expect(broker.open_orders).to be_empty
      expect(portfolio.positions["SOLUSDT"].quantity.to_f).to eq(10.0)
      expect(portfolio.positions["SOLUSDT"].entry_price.to_f).to eq(100.1)
      expect(portfolio.cash_balance.to_f).to eq(9_999.4995)

      events = event_store.find_by_type(:OrderFilled)
      expect(events).not_to be_empty
    end

    it "reverses a long position to a short position" do
      order_long = OrderRequest.new(
        symbol: "SOLUSDT",
        side: :buy,
        quantity: 10.0,
        order_type: :market
      )
      broker.submit_order(order_long)
      broker.process_candle(candle, 100.0, "SOLUSDT")

      order_sell = OrderRequest.new(
        symbol: "SOLUSDT",
        side: :sell,
        quantity: 15.0,
        order_type: :market
      )
      broker.submit_order(order_sell)

      broker.process_candle(candle, 105.0, "SOLUSDT")

      expect(portfolio.positions["SOLUSDT"].side).to eq(:short)
      expect(portfolio.positions["SOLUSDT"].quantity.to_f).to eq(5.0)
      expect(portfolio.positions["SOLUSDT"].entry_price.to_f).to eq(104.895)
    end
  end
end
