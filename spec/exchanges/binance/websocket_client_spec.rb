# frozen_string_literal: true

require "rails_helper"
require_relative "../../../app/exchanges/binance/websocket_client"

RSpec.describe Exchanges::Binance::WebsocketClient do
  describe "#initialize" do
    it "initializes with default URL" do
      client = described_class.new
      expect(client.ws_url).to eq("wss://stream.binancefuture.com/ws")
    end

    it "initializes with custom URL" do
      client = described_class.new(ws_url: "wss://custom.url.com")
      expect(client.ws_url).to eq("wss://custom.url.com")
    end

    it "starts in disconnected state" do
      client = described_class.new
      expect(client.status).to eq(:disconnected)
    end
  end

  describe "#on" do
    it "registers a callback for an event" do
      client = described_class.new
      callback_called = false

      client.on(:connected) do
        callback_called = true
      end

      # Manually trigger callback for testing
      client.send(:trigger, :connected, nil)

      expect(callback_called).to be true
    end
  end

  describe "#reconnect_with_backoff" do
    let(:client) { described_class.new(ws_url: "wss://fstream.binance.com/stream?streams=btcusdt@ticker") }

    before do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)
      allow(client).to receive(:connect)
      allow(client).to receive(:disconnect)
    end

    it "retries connection with exponential backoff delays" do
      connect_calls = 0
      allow(client).to receive(:connect) do
        connect_calls += 1
        raise StandardError.new("Connection failed") if connect_calls < 3
        true
      end

      result = client.reconnect_with_backoff(max_attempts: 3)

      # First attempt + 2 retries = 3 total connect calls
      expect(connect_calls).to eq(3)
      expect(result).to be true
    end

    it "returns true on successful connection" do
      allow(client).to receive(:connect).and_return(true)

      result = client.reconnect_with_backoff(max_attempts: 3)

      expect(result).to be true
    end

    it "returns false when all attempts fail" do
      allow(client).to receive(:connect).and_raise(StandardError.new("Connection failed"))

      result = client.reconnect_with_backoff(max_attempts: 2)

      expect(result).to be false
    end

    it "respects max_attempts parameter" do
      allow(client).to receive(:connect).and_raise(StandardError.new("Connection failed"))

      # Should only sleep for the retry delays, not the final failed attempt
      expect(client).to receive(:sleep).exactly(2).times

      client.reconnect_with_backoff(max_attempts: 3)
    end
  end

  describe "private methods" do
    describe "#build_url" do
      it "appends /ws to standard URLs without /stream" do
        client = described_class.new(ws_url: "wss://fapi.binance.com")
        url = client.send(:build_url)
        expect(url).to eq("wss://fapi.binance.com/ws")
      end

      it "does not append /ws to combined stream URLs" do
        client = described_class.new(ws_url: "wss://fstream.binance.com/stream?streams=btcusdt@ticker")
        url = client.send(:build_url)
        expect(url).to eq("wss://fstream.binance.com/stream?streams=btcusdt@ticker")
      end

      it "does not append /ws to URLs already ending with /ws" do
        client = described_class.new(ws_url: "wss://stream.binancefuture.com/ws")
        url = client.send(:build_url)
        expect(url).to eq("wss://stream.binancefuture.com/ws")
      end

      it "appends listen_key correctly to combined stream URL" do
        client = described_class.new(ws_url: "wss://fstream.binance.com/stream?streams=btcusdt@ticker")
        url = client.send(:build_url, "test_listen_key_123")
        expect(url).to eq("wss://fstream.binance.com/stream?streams=btcusdt@ticker/test_listen_key_123")
      end
    end
  end
end