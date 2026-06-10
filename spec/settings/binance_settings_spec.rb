# frozen_string_literal: true

require "rails_helper"

RSpec.describe BinanceSettings do
  around do |example|
    original_env = ENV.to_hash

    example.run
  ensure
    ENV.replace(original_env)
  end

  before do
    ENV["BINANCE_API_KEY"] = "key"
    ENV["BINANCE_API_SECRET"] = "secret"

    ENV["BINANCE_BASE_URL"] = "https://fapi.binance.com"
    ENV["BINANCE_WS_URL"] = "https://fstream.binance.com"

    ENV["BINANCE_TESTNET_ENABLED"] = "false"
  end

  describe ".api_key" do
    it "returns the api key" do
      expect(described_class.api_key).to eq("key")
    end
  end

  describe ".api_secret" do
    it "returns the api secret" do
      expect(described_class.api_secret).to eq("secret")
    end
  end

  describe ".testnet?" do
    it "returns false by default" do
      expect(described_class.testnet?).to be(false)
    end

    it "returns true when enabled" do
      ENV["BINANCE_TESTNET_ENABLED"] = "true"

      expect(described_class.testnet?).to be(true)
    end
  end

  describe ".validate!" do
    it "passes with valid configuration" do
      expect(described_class.validate!).to be(true)
    end

    it "raises when api key is missing" do
      ENV.delete("BINANCE_API_KEY")

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "Missing required environment variable: BINANCE_API_KEY"
      )
    end

    it "raises for invalid base url" do
      ENV["BINANCE_BASE_URL"] = "invalid-url"

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "Invalid URL: invalid-url"
      )
    end

    it "raises for invalid websocket url" do
      ENV["BINANCE_WS_URL"] = "invalid-url"

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "Invalid URL: invalid-url"
      )
    end
  end
end