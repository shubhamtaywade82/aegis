# frozen_string_literal: true

require "rails_helper"

RSpec.describe Candle do
  subject(:candle) do
    described_class.new(
      open_time: Time.current,
      open: 100,
      high: 110,
      low: 95,
      close: 105,
      volume: 1000,
      close_time: Time.current,
      quote_volume: 100_000,
      trade_count: 50,
      taker_buy_base_volume: 500,
      taker_buy_quote_volume: 50_000
    )
  end

  it { expect(candle.bullish?).to be(true) }
  it { expect(candle.bearish?).to be(false) }
  it { expect(candle.range).to eq(15) }
  it { expect(candle.body_size).to eq(5) }
end
