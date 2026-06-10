# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResearchSettings do
  around do |example|
    original_env = ENV.to_hash

    example.run
  ensure
    ENV.replace(original_env)
  end

  before do
    ENV["OPTIMIZATION_BARS"] = "500"
    ENV["FORWARD_BARS"] = "100"

    ENV["MINIMUM_TRADES"] = "20"

    ENV["ATR_STOP_MULTIPLIER"] = "1.0"
    ENV["REWARD_RISK_RATIO"] = "2.0"
  end

  describe ".validate!" do
    it "passes with valid settings" do
      expect(described_class.validate!).to be(true)
    end

    it "raises when optimization bars are not greater" do
      ENV["OPTIMIZATION_BARS"] = "100"
      ENV["FORWARD_BARS"] = "100"

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "OPTIMIZATION_BARS must be greater than FORWARD_BARS"
      )
    end

    it "raises when minimum trades is invalid" do
      ENV["MINIMUM_TRADES"] = "0"

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "MINIMUM_TRADES must be greater than zero"
      )
    end

    it "raises when atr multiplier is invalid" do
      ENV["ATR_STOP_MULTIPLIER"] = "0"

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "ATR_STOP_MULTIPLIER must be greater than zero"
      )
    end

    it "raises when reward risk is invalid" do
      ENV["REWARD_RISK_RATIO"] = "0"

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "REWARD_RISK_RATIO must be greater than zero"
      )
    end
  end

  describe "defaults" do
    it "uses default values" do
      ENV.delete("OPTIMIZATION_BARS")
      ENV.delete("FORWARD_BARS")
      ENV.delete("MINIMUM_TRADES")
      ENV.delete("ATR_STOP_MULTIPLIER")
      ENV.delete("REWARD_RISK_RATIO")

      expect(described_class.optimization_bars).to eq(500)
      expect(described_class.forward_bars).to eq(100)
      expect(described_class.minimum_trades).to eq(20)

      expect(described_class.atr_stop_multiplier).to eq(1.0)
      expect(described_class.reward_risk_ratio).to eq(2.0)
    end
  end
end