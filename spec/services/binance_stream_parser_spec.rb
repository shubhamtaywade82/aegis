# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/services/binance_stream_parser"

RSpec.describe BinanceStreamParser do
  describe ".parse" do
    context "with combined stream format (ticker)" do
      let(:combined_ticker_message) do
        {
          "stream" => "btcusdt@ticker",
          "data" => {
            "e" => "24hrTicker",
            "E" => 1_234_567_890,
            "s" => "BTCUSDT",
            "c" => "97000.00",
            "o" => "96000.00",
            "h" => "98000.00",
            "l" => "95000.00",
            "v" => "100.5",
            "q" => "9700000.00"
          }
        }.to_json
      end

      it "parses combined stream ticker message correctly" do
        result = described_class.parse(combined_ticker_message)

        expect(result).to be_a(BinanceStreamParser::ParseResult)
        expect(result.stream).to eq("btcusdt@ticker")
        expect(result.event_type).to eq("24hrTicker")
        expect(result.symbol).to eq("BTCUSDT")
        expect(result.data["c"]).to eq("97000.00")
      end
    end

    context "with combined stream format (kline)" do
      let(:combined_kline_message) do
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
        }.to_json
      end

      it "parses combined stream kline message correctly" do
        result = described_class.parse(combined_kline_message)

        expect(result).to be_a(BinanceStreamParser::ParseResult)
        expect(result.stream).to eq("btcusdt@kline_1m")
        expect(result.event_type).to eq("kline")
        expect(result.symbol).to eq("BTCUSDT")
        expect(result.data["k"]["c"]).to eq("96800.00")
      end
    end

    context "with single stream format" do
      let(:single_stream_message) do
        {
          "e" => "24hrTicker",
          "E" => 1_234_567_890,
          "s" => "ETHUSDT",
          "c" => "3500.00"
        }.to_json
      end

      it "parses single stream message correctly" do
        result = described_class.parse(single_stream_message)

        expect(result).to be_a(BinanceStreamParser::ParseResult)
        expect(result.stream).to be_nil
        expect(result.event_type).to eq("24hrTicker")
        expect(result.symbol).to eq("ETHUSDT")
        expect(result.data["c"]).to eq("3500.00")
      end
    end

    context "with already-parsed hash" do
      let(:parsed_hash) do
        {
          "stream" => "solusdt@ticker",
          "data" => {
            "e" => "24hrTicker",
            "s" => "SOLUSDT",
            "c" => "140.25"
          }
        }
      end

      it "handles already-parsed hash without re-parsing" do
        result = described_class.parse(parsed_hash)

        expect(result).to be_a(BinanceStreamParser::ParseResult)
        expect(result.symbol).to eq("SOLUSDT")
      end
    end

    context "with invalid JSON" do
      let(:invalid_json) { "{ invalid json }" }

      it "returns nil for invalid JSON" do
        result = described_class.parse(invalid_json)
        expect(result).to be_nil
      end
    end
  end

  describe ".extract_symbol" do
    it "extracts symbol from ticker stream" do
      symbol = described_class.extract_symbol("btcusdt@ticker")
      expect(symbol).to eq("BTCUSDT")
    end

    it "extracts symbol from kline stream" do
      symbol = described_class.extract_symbol("ethusdt@kline_1m")
      expect(symbol).to eq("ETHUSDT")
    end

    it "returns nil for nil input" do
      symbol = described_class.extract_symbol(nil)
      expect(symbol).to be_nil
    end
  end
end
