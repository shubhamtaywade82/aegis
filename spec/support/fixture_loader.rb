# frozen_string_literal: true

require "json"

module FixtureLoader
  module_function

  def load_binance_fixture(filename)
    path = Rails.root.join("spec/fixtures/binance", filename)
    raw_data = JSON.parse(File.read(path))

    candles = raw_data.map do |kline|
      Candle.new(
        open_time: Time.at(kline[0] / 1000.0),
        open: kline[1].to_f,
        high: kline[2].to_f,
        low: kline[3].to_f,
        close: kline[4].to_f,
        volume: kline[5].to_f,
        close_time: Time.at(kline[6] / 1000.0),
        quote_volume: kline[7].to_f,
        trade_count: kline[8].to_i,
        taker_buy_base_volume: kline[9].to_f,
        taker_buy_quote_volume: kline[10].to_f
      )
    end

    Research::CandleSeries.new(candles)
  end
end
