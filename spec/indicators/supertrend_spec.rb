# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/indicators/atr"
require_relative "../../app/indicators/supertrend"

RSpec.describe Indicators::Supertrend do
  it "calculates supertrend" do
    candles =
      30.times.map do |i|
        Candle.new(
          open_time: Time.current,
          open: 100 + i * 2,
          high: 105 + i * 2,
          low: 95 + i * 2,
          close: 102 + i * 2,
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
