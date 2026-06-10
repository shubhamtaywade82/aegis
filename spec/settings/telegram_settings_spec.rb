# frozen_string_literal: true

require "rails_helper"

RSpec.describe TelegramSettings do
  around do |example|
    original_env = ENV.to_hash

    example.run
  ensure
    ENV.replace(original_env)
  end

  describe ".enabled?" do
    it "returns false when not configured" do
      ENV.delete("TELEGRAM_BOT_TOKEN")
      ENV.delete("TELEGRAM_CHAT_ID")

      expect(described_class.enabled?).to be(false)
    end

    it "returns true when partially configured" do
      ENV["TELEGRAM_BOT_TOKEN"] = "token"

      expect(described_class.enabled?).to be(true)
    end
  end

  describe ".validate!" do
    it "passes when disabled" do
      ENV.delete("TELEGRAM_BOT_TOKEN")
      ENV.delete("TELEGRAM_CHAT_ID")

      expect(described_class.validate!).to be(true)
    end

    it "passes when fully configured" do
      ENV["TELEGRAM_BOT_TOKEN"] = "token"
      ENV["TELEGRAM_CHAT_ID"] = "123"

      expect(described_class.validate!).to be(true)
    end

    it "fails when only bot token exists" do
      ENV["TELEGRAM_BOT_TOKEN"] = "token"
      ENV.delete("TELEGRAM_CHAT_ID")

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must both be configured"
      )
    end

    it "fails when only chat id exists" do
      ENV.delete("TELEGRAM_BOT_TOKEN")
      ENV["TELEGRAM_CHAT_ID"] = "123"

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must both be configured"
      )
    end
  end
end
