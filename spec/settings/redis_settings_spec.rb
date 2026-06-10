# frozen_string_literal: true

require "rails_helper"

RSpec.describe RedisSettings do
  around do |example|
    original_env = ENV.to_hash

    example.run
  ensure
    ENV.replace(original_env)
  end

  before do
    ENV["REDIS_URL"] = "redis://localhost:6379/0"
  end

  describe ".url" do
    it "returns the url" do
      expect(described_class.url).to eq("redis://localhost:6379/0")
    end
  end

  describe ".validate!" do
    it "passes with valid config" do
      expect(described_class.validate!).to be(true)
    end

    it "raises when REDIS_URL is missing" do
      ENV.delete("REDIS_URL")

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "Missing required environment variable: REDIS_URL"
      )
    end

    it "raises when REDIS_URL is invalid" do
      ENV["REDIS_URL"] = "invalid_url"

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "REDIS_URL must be a valid URI"
      )
    end
  end
end
