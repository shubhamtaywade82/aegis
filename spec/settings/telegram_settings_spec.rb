# frozen_string_literal: true

require "rails_helper"

RSpec.describe TelegramSettings do
  around do |example|
    original_env = ENV.to_hash

    example.run
  ensure
    ENV.replace(original_env)
  end

  before do
    ENV["TELEGRAM_BOT_TOKEN"] = "token"
    ENV["TELEGRAM_CHAT_ID"] = "123456"
  end

  describe ".bot_token" do
    it "returns the bot token" do
      expect(described_class.bot_token).to eq("token")
    end
  end

  describe ".chat_id" do
    it "returns the chat id" do
      expect(described_class.chat_id).to eq("123456")
    end
  end

  describe ".enabled?" do
    it "returns true when both are present" do
      expect(described_class.enabled?).to be(true)
    end

    it "returns false when bot_token is empty" do
      ENV["TELEGRAM_BOT_TOKEN"] = ""

      expect(described_class.enabled?).to be(false)
    end

    it "returns false when chat_id is empty" do
      ENV["TELEGRAM_CHAT_ID"] = ""

      expect(described_class.enabled?).to be(false)
    end
  end

  describe ".validate!" do
    it "passes with valid config" do
      expect(described_class.validate!).to be(true)
    end

    it "passes when both are empty" do
      ENV.delete("TELEGRAM_BOT_TOKEN")
      ENV.delete("TELEGRAM_CHAT_ID")

      expect(described_class.validate!).to be(true)
    end

    it "raises when token is present but chat_id is missing" do
      ENV.delete("TELEGRAM_CHAT_ID")

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "TELEGRAM_CHAT_ID is required when TELEGRAM_BOT_TOKEN is set"
      )
    end

    it "raises when chat_id is present but token is missing" do
      ENV.delete("TELEGRAM_BOT_TOKEN")

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "TELEGRAM_BOT_TOKEN is required when TELEGRAM_CHAT_ID is set"
      )
    end
  end
end