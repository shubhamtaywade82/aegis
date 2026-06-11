# frozen_string_literal: true

require "rails_helper"

RSpec.describe Binance::HistoricalClient, :integration do
  subject(:client) do
    base_url = ENV["BINANCE_BASE_URL"] || "https://fapi.binance.com"
    described_class.new(base_url: base_url)
  end

  describe "#klines" do
    it "successfully downloads historical klines from the Binance API" do
      result = client.klines(symbol: "SOLUSDT", interval: "1h", limit: 10)

      expect(result).to be_an(Array)
      expect(result.size).to eq(10)

      kline = result.first
      expect(kline).to be_an(Array)
      expect(kline.size).to be >= 11 # Binance Futures klines have at least 11-12 elements

      # Check open time (Integer timestamp)
      expect(kline[0]).to be_a(Integer)
      # Check prices (Strings)
      expect(kline[1]).to be_a(String) # Open
      expect(kline[2]).to be_a(String) # High
      expect(kline[3]).to be_a(String) # Low
      expect(kline[4]).to be_a(String) # Close
      expect(kline[5]).to be_a(String) # Volume
    end
  end
end
