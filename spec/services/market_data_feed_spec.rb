# frozen_string_literal: true

require "rails_helper"

RSpec.describe MarketDataFeed do
  let(:redis) { instance_double(Redis) }
  let(:feed) { described_class.new(symbols: %w[BTCUSDT ETHUSDT SOLUSDT]) }

  before do
    allow(Redis).to receive(:new).and_return(redis)
    allow(redis).to receive(:close)
    allow(RealtimeSupertrend).to receive(:calculate_for)
    allow(MatchingEngine).to receive(:process_ticker_tick)
  end

  describe "#initialize" do
    it "accepts custom symbols list" do
      custom_feed = described_class.new(symbols: %w[BNBUSDT])
      expect(custom_feed.symbols).to eq(%w[BNBUSDT])
    end

    it "uses default symbols when none provided" do
      default_feed = described_class.new
      expect(default_feed.symbols).to eq(%w[BTCUSDT ETHUSDT SOLUSDT BNBUSDT XRPUSDT ADAUSDT DOGEUSDT])
    end

    it "initializes with a Redis connection" do
      expect(Redis).to receive(:new).and_return(redis)
      described_class.new
    end
  end

  describe "#latest_tick" do
    before do
      allow(Redis).to receive(:new).and_return(redis)
    end

    it "returns parsed tick data from Redis" do
      tick_data = { "c" => "97000.00", "s" => "BTCUSDT" }.to_json
      allow(redis).to receive(:get).with("trading:ticks:BTCUSDT").and_return(tick_data)

      result = feed.latest_tick("BTCUSDT")
      expect(result["c"]).to eq("97000.00")
    end

    it "returns nil when no tick data exists" do
      allow(redis).to receive(:get).with("trading:ticks:UNKNOWN").and_return(nil)

      result = feed.latest_tick("UNKNOWN")
      expect(result).to be_nil
    end
  end

  describe "#latest_kline" do
    before do
      allow(Redis).to receive(:new).and_return(redis)
    end

    it "returns parsed kline data from Redis" do
      kline_data = { "t" => 1_234_560_000, "c" => "96800.00" }.to_json
      allow(redis).to receive(:get).with("trading:klines:BTCUSDT").and_return(kline_data)

      result = feed.latest_kline("BTCUSDT")
      expect(result["c"]).to eq("96800.00")
    end

    it "returns nil when no kline data exists" do
      allow(redis).to receive(:get).with("trading:klines:UNKNOWN").and_return(nil)

      result = feed.latest_kline("UNKNOWN")
      expect(result).to be_nil
    end
  end

  describe "#closed_klines" do
    before do
      allow(Redis).to receive(:new).and_return(redis)
    end

    it "returns closed klines from history list" do
      kline1 = { "t" => 1_234_560_000, "c" => "96500.00" }.to_json
      kline2 = { "t" => 1_234_566_000, "c" => "96800.00" }.to_json
      allow(redis).to receive(:lrange)
        .with("trading:klines:BTCUSDT:history", 0, 29)
        .and_return([ kline2, kline1 ])

      result = feed.closed_klines("BTCUSDT", count: 30)
      expect(result.size).to eq(2)
      expect(result.first["c"]).to eq("96800.00")
    end

    it "defaults to 30 klines when count not specified" do
      allow(redis).to receive(:lrange)
        .with("trading:klines:BTCUSDT:history", 0, 29)
        .and_return([])

      feed.closed_klines("BTCUSDT")
      expect(redis).to have_received(:lrange).with("trading:klines:BTCUSDT:history", 0, 29)
    end
  end

  describe "#process_message" do
    let(:ticker_message) do
      {
        "stream" => "btcusdt@ticker",
        "data" => {
          "e" => "24hrTicker",
          "s" => "BTCUSDT",
          "c" => "97000.00",
          "o" => "96000.00",
          "h" => "98000.00",
          "l" => "95000.00",
          "v" => "100.5",
          "q" => "9700000.00"
        }
      }
    end

    let(:kline_message) do
      {
        "stream" => "btcusdt@kline_1m",
        "data" => {
          "e" => "kline",
          "E" => 1_234_567_890,
          "s" => "BTCUSDT",
          "k" => {
            "t" => 1_234_560_000,
            "T" => 1_234_565_999,
            "s" => "BTCUSDT",
            "i" => "1m",
            "o" => "96000.00",
            "c" => "96800.00",
            "h" => "97000.00",
            "l" => "95500.00",
            "v" => "1.5",
            "q" => "145200.00",
            "n" => 150,
            "V" => "0.8",
            "Q" => "77440.00",
            "x" => false
          }
        }
      }
    end

    let(:closed_kline_message) do
      {
        "stream" => "btcusdt@kline_1m",
        "data" => {
          "e" => "kline",
          "s" => "BTCUSDT",
          "k" => {
            "t" => 1_234_560_000,
            "T" => 1_234_565_999,
            "o" => "96000.00",
            "c" => "96800.00",
            "h" => "97000.00",
            "l" => "95500.00",
            "v" => "1.5",
            "q" => "145200.00",
            "n" => 150,
            "V" => "0.8",
            "Q" => "77440.00",
            "x" => true
          }
        }
      }
    end

    before do
      allow(Redis).to receive(:new).and_return(redis)
      allow(redis).to receive(:setex).and_return("OK")
      allow(redis).to receive(:lpush).and_return(1)
      allow(redis).to receive(:ltrim).and_return("OK")
      allow(ActionCable).to receive(:server).and_return(double("server", broadcast: nil))
    end

    context "with ticker message" do
      it "stores ticker data in Redis with TTL" do
        allow(redis).to receive(:setex)
        expect(redis).to receive(:setex)
          .with("trading:ticks:BTCUSDT", 60, anything)

        feed.process_message(ticker_message)
      end

      it "broadcasts ticker update via ActionCable" do
        expect(ActionCable.server).to receive(:broadcast)
          .with("trading:BTCUSDT", hash_including(type: "ticker", symbol: "BTCUSDT"))

        feed.process_message(ticker_message)
      end
    end

    context "with open kline message" do
      it "stores kline data in Redis but does not push to history" do
        expect(redis).to receive(:setex)
          .with("trading:klines:BTCUSDT", 60, anything)
        expect(redis).not_to receive(:lpush)

        feed.process_message(kline_message)
      end

      it "broadcasts kline update via ActionCable" do
        expect(ActionCable.server).to receive(:broadcast)
          .with("trading:BTCUSDT", hash_including(type: "kline_closed")).never

        feed.process_message(kline_message)
      end
    end

    context "with closed kline message" do
      it "stores kline data in Redis" do
        expect(redis).to receive(:setex)
          .with("trading:klines:BTCUSDT", 60, anything)

        feed.process_message(closed_kline_message)
      end

      it "pushes closed kline to history list" do
        expect(redis).to receive(:lpush)
          .with("trading:klines:BTCUSDT:history", anything)
        expect(redis).to receive(:ltrim)
          .with("trading:klines:BTCUSDT:history", 0, 499)

        feed.process_message(closed_kline_message)
      end

      it "broadcasts kline_closed via ActionCable" do
        expect(ActionCable.server).to receive(:broadcast)
          .with("trading:BTCUSDT", hash_including(type: "kline_closed", symbol: "BTCUSDT"))

        feed.process_message(closed_kline_message)
      end
    end

    context "with unparseable message" do
      it "does not raise error" do
        expect {
          feed.process_message({})
        }.not_to raise_error
      end
    end
  end

  describe "#start and #stop" do
    let(:ws_client) { instance_double("Exchanges::Binance::WebsocketClient") }

    before do
      allow(Redis).to receive(:new).and_return(redis)
      allow(feed).to receive(:seed_historical_klines)
      allow(Exchanges::Binance::WebsocketClient).to receive(:new).and_return(ws_client)
      allow(ws_client).to receive(:on)
      allow(ws_client).to receive(:connect)
      allow(ws_client).to receive(:disconnect)
    end

    it "creates WebSocket client with combined stream URL" do
      expect(Exchanges::Binance::WebsocketClient).to receive(:new)
        .with(ws_url: /wss:\/\/fstream\.binance\.com\/market\/stream\?streams=/)

      feed.start
    end

    it "sets up message handler" do
      expect(ws_client).to receive(:on).with(:message)

      feed.start
    end

    it "connects the WebSocket" do
      expect(ws_client).to receive(:connect)

      feed.start
    end

    it "stops the WebSocket on stop" do
      feed.start
      expect(ws_client).to receive(:disconnect)
      expect(redis).to receive(:close)

      feed.stop
    end
  end
end
