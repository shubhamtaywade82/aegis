# frozen_string_literal: true

require "rails_helper"

RSpec.describe Indicators::Supertrend do
  it "calculates supertrend" do
    candles =
      30.times.map do |i|
        Candle.new(
          open_time: Time.current,
          open: 100 + i,
          high: 105 + i,
          low: 95 + i,
          close: 102 + i,
          volume: 1,
          close_time: Time.current,
          quote_volume: 0,
          trade_count: 0,
          taker_buy_base_volume: 0,
          taker_buy_quote_volume: 0
        )
      end

    results =
      described_class.calculate(
        candles: candles,
        period: 10,
        multiplier: 3.0
      )

    expect(results.size).to eq(30)
    expect(results.compact.last.direction).to eq(:bullish)
  end
end
