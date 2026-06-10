# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/research/candle_series"

RSpec.describe Research::CandleSeries do
  let(:candles) do
    Array.new(3) do |i|
      Candle.new(
        open_time: Time.current,
        open: 100 + i,
        high: 110 + i,
        low: 90 + i,
        close: 105 + i,
        volume: 1_000,
        close_time: Time.current,
        quote_volume: 0,
        trade_count: 0,
        taker_buy_base_volume: 0,
        taker_buy_quote_volume: 0
      )
    end
  end

  subject(:series) { described_class.new(candles) }

  it "returns closes" do
    expect(series.closes).to eq([ 105, 106, 107 ])
  end

  it "supports windows" do
    expect(series.window(2).count).to eq(2)
  end

  it "returns slices" do
    expect(series.slice(1, 2).size).to eq(2)
  end
end
