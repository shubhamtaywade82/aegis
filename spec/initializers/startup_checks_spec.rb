# frozen_string_literal: true

require "rails_helper"

RSpec.describe "startup_checks initializer" do
  let(:initializer_path) { Rails.root.join("config/initializers/startup_checks.rb") }

  describe "initializer file" do
    it "exists" do
      expect(File.exist?(initializer_path)).to be(true)
    end

    it "contains Settings.validate! call" do
      content = File.read(initializer_path)
      expect(content).to include("Settings.validate!")
    end

    it "uses after_initialize block" do
      content = File.read(initializer_path)
      expect(content).to include("after_initialize")
    end

    it "rescues ConfigurationError" do
      content = File.read(initializer_path)
      expect(content).to include("rescue ConfigurationError")
    end

    it "uses Kernel.abort on ConfigurationError" do
      content = File.read(initializer_path)
      expect(content).to include("Kernel.abort")
    end

    it "formats abort message with CONFIGURATION ERROR header" do
      content = File.read(initializer_path)
      expect(content).to include("=== CONFIGURATION ERROR ===")
    end
  end

  describe "Settings.validate! behavior" do
    around do |example|
      original_env = ENV.to_hash

      example.run
    ensure
      ENV.replace(original_env)
    end

    before do
      # Valid Binance settings
      ENV["BINANCE_API_KEY"] = "key"
      ENV["BINANCE_API_SECRET"] = "secret"
      ENV["BINANCE_BASE_URL"] = "https://fapi.binance.com"
      ENV["BINANCE_WS_URL"] = "https://fstream.binance.com"
      ENV["BINANCE_TESTNET_ENABLED"] = "false"

      # Valid Research settings
      ENV["OPTIMIZATION_BARS"] = "500"
      ENV["FORWARD_BARS"] = "100"
      ENV["MINIMUM_TRADES"] = "20"
      ENV["ATR_STOP_MULTIPLIER"] = "1.0"
      ENV["REWARD_RISK_RATIO"] = "2.0"

      # Valid Sidekiq settings
      ENV["SIDEKIQ_CONCURRENCY"] = "10"

      # Valid Redis settings
      ENV["REDIS_URL"] = "redis://localhost:6379/0"

      # Valid Telegram settings (both empty/disabled by default)
      ENV.delete("TELEGRAM_BOT_TOKEN")
      ENV.delete("TELEGRAM_CHAT_ID")
    end

    it "passes with valid configurations" do
      expect(Settings.validate!).to be(true)
    end

    it "raises ConfigurationError when Telegram has partial config" do
      ENV["TELEGRAM_BOT_TOKEN"] = "token"
      ENV.delete("TELEGRAM_CHAT_ID")

      expect { Settings.validate! }.to raise_error(ConfigurationError)
    end

    it "raises ConfigurationError when Sidekiq concurrency is invalid" do
      ENV["SIDEKIQ_CONCURRENCY"] = "0"

      expect { Settings.validate! }.to raise_error(ConfigurationError)
    end

    it "raises ConfigurationError when Redis URL is invalid" do
      ENV["REDIS_URL"] = "invalid"

      expect { Settings.validate! }.to raise_error(ConfigurationError)
    end
  end
end