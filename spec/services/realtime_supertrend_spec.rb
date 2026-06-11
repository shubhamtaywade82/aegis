# frozen_string_literal: true

require "rails_helper"

RSpec.describe RealtimeSupertrend do
  let(:redis) { instance_double(Redis) }
  let(:supertrend_result) do
    Struct.new(:direction, :value, :upper_band, :lower_band).new(
      :bullish, 96800.5, 97500.0, 95400.0
    )
  end

  def make_kline(t, o, h, l, c, v)
    {
      "t" => t,
      "o" => o.to_s,
      "h" => h.to_s,
      "l" => l.to_s,
      "c" => c.to_s,
      "v" => v.to_s
    }.to_json
  end

  before do
    allow(MarketDataFeed).to receive(:redis).and_return(redis)
  end

  describe ".calculate_for" do
    it "fetches last 30 klines from Redis history" do
      allow(redis).to receive(:lrange).with("trading:klines:BTCUSDT:history", 0, 29).and_return([])
      allow(Indicators::Supertrend).to receive(:calculate).and_return([])

      described_class.calculate_for("BTCUSDT")

      expect(redis).to have_received(:lrange).with("trading:klines:BTCUSDT:history", 0, 29)
    end

    it "converts kline JSON to Candle objects and calls Supertrend" do
      klines = [
        make_kline(1_234_560_000, "96000", "97000", "95500", "96800", "1.5"),
        make_kline(1_234_566_000, "96800", "97500", "96000", "97000", "1.6")
      ]
      allow(redis).to receive(:lrange).and_return(klines)
      allow(Indicators::Supertrend).to receive(:calculate).and_return([])

      described_class.calculate_for("BTCUSDT")

      expect(Indicators::Supertrend).to have_received(:calculate) do |kwargs|
        candles = kwargs[:candles]
        expect(candles).to be_a(Array)
        expect(candles.all? { |c| c.is_a?(Candle) }).to be true
      end
    end

    it "calls Supertrend.calculate with correct parameters" do
      allow(redis).to receive(:lrange).and_return([
        make_kline(1_234_560_000, "96000", "97000", "95500", "96800", "1.5"),
        make_kline(1_234_566_000, "96800", "97500", "96000", "97000", "1.6")
      ])
      allow(Indicators::Supertrend).to receive(:calculate).and_return([])

      described_class.calculate_for("BTCUSDT")

      expect(Indicators::Supertrend).to have_received(:calculate).with(
        candles: anything,
        period: 10,
        multiplier: 3.0
      )
    end

    it "stores result in Redis with TTL" do
      allow(redis).to receive(:lrange).and_return([
        make_kline(1_234_560_000, "96000", "97000", "95500", "96800", "1.5"),
        make_kline(1_234_566_000, "96800", "97500", "96000", "97000", "1.6")
      ])
      allow(redis).to receive(:setex).and_return("OK")
      allow(Indicators::Supertrend).to receive(:calculate).and_return([nil, supertrend_result])

      described_class.calculate_for("BTCUSDT")

      expect(redis).to have_received(:setex).with(
        "trading:supertrend:BTCUSDT",
        60,
        /"direction":"BULLISH"/
      )
    end

    it "broadcasts result via ActionCable" do
      allow(redis).to receive(:lrange).and_return([
        make_kline(1_234_560_000, "96000", "97000", "95500", "96800", "1.5"),
        make_kline(1_234_566_000, "96800", "97500", "96000", "97000", "1.6")
      ])
      allow(redis).to receive(:setex).and_return("OK")
      allow(Indicators::Supertrend).to receive(:calculate).and_return([nil, supertrend_result])
      allow(ActionCable.server).to receive(:broadcast)

      described_class.calculate_for("BTCUSDT")

      expect(ActionCable.server).to have_received(:broadcast).with(
        "trading:BTCUSDT",
        hash_including(type: "supertrend", symbol: "BTCUSDT", direction: "BULLISH")
      )
    end

    it "returns the last valid result" do
      results = [
        nil,
        supertrend_result
      ]
      allow(redis).to receive(:lrange).and_return([
        make_kline(1_234_560_000, "96000", "97000", "95500", "96800", "1.5"),
        make_kline(1_234_566_000, "96800", "97500", "96000", "97000", "1.6")
      ])
      allow(redis).to receive(:setex).and_return("OK")
      allow(Indicators::Supertrend).to receive(:calculate).and_return(results)

      result = described_class.calculate_for("BTCUSDT")

      expect(result).to eq(supertrend_result)
    end

    it "returns nil when fewer than 2 candles" do
      allow(redis).to receive(:lrange).and_return([])

      result = described_class.calculate_for("BTCUSDT")

      expect(result).to be_nil
    end

    it "returns nil when no valid results from Supertrend" do
      allow(redis).to receive(:lrange).and_return([
        make_kline(1_234_560_000, "96000", "97000", "95500", "96800", "1.5"),
        make_kline(1_234_566_000, "96800", "97500", "96000", "97000", "1.6")
      ])
      allow(Indicators::Supertrend).to receive(:calculate).and_return([nil, nil])

      result = described_class.calculate_for("BTCUSDT")

      expect(result).to be_nil
    end
  end

  describe ".latest_for" do
    it "returns parsed supertrend data from Redis" do
      data = {
        "direction" => "BULLISH",
        "value" => 96800.5,
        "upper_band" => 97500.0,
        "lower_band" => 95400.0
      }.to_json

      allow(redis).to receive(:get).with("trading:supertrend:BTCUSDT").and_return(data)

      result = described_class.latest_for("BTCUSDT")

      expect(result[:direction]).to eq("BULLISH")
      expect(result[:value]).to eq(96800.5)
      expect(result[:upper_band]).to eq(97500.0)
      expect(result[:lower_band]).to eq(95400.0)
    end

    it "returns nil when no data in Redis" do
      allow(redis).to receive(:get).and_return(nil)

      result = described_class.latest_for("BTCUSDT")

      expect(result).to be_nil
    end
  end

  describe "candle parsing" do
    it "creates Candle with correct fields from kline JSON" do
      klines = [
        make_kline(1_234_560_000, "96000", "97000", "95500", "96800", "1.5"),
        make_kline(1_234_566_000, "96800", "97500", "96000", "97000", "1.6")
      ]
      allow(redis).to receive(:lrange).and_return(klines)
      allow(Indicators::Supertrend).to receive(:calculate).and_return([])

      described_class.calculate_for("BTCUSDT")

      expect(Indicators::Supertrend).to have_received(:calculate) do |kwargs|
        candles = kwargs[:candles]
        # After reversing, oldest (earlier timestamp) is first
        earliest = candles.min_by { |c| c.open_time }
        expect(earliest.open_time).to eq(1_234_560_000)
        expect(earliest.close_time).to eq(1_234_619_999)
        expect(earliest.open).to eq(BigDecimal("96000"))
        expect(earliest.close).to eq(BigDecimal("96800"))
      end
    end
  end
end