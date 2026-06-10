# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/indicators/atr"

RSpec.describe Indicators::ATR do
  it "calculates atr" do
    candles =
      20.times.map do |i|
        Candle.new(
          open_time: Time.current,
          open: 100,
          high: 110 + i,
          low: 90,
          close: 100,
          volume: 1,
          close_time: Time.current,
          quote_volume: 0,
          trade_count: 0,
          taker_buy_base_volume: 0,
          taker_buy_quote_volume: 0
        )
      end

    atr =
      described_class.calculate(
        candles: candles,
        period: 14
      )

    expect(atr.size).to eq(20)
    expect(atr.last).not_to be_nil
  end
end
