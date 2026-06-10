# frozen_string_literal: true

require "rails_helper"

RSpec.describe SidekiqSettings do
  around do |example|
    original_env = ENV.to_hash

    example.run
  ensure
    ENV.replace(original_env)
  end

  describe ".concurrency" do
    it "uses configured value" do
      ENV["SIDEKIQ_CONCURRENCY"] = "25"

      expect(described_class.concurrency).to eq(25)
    end

    it "uses default value" do
      ENV.delete("SIDEKIQ_CONCURRENCY")

      expect(described_class.concurrency).to eq(10)
    end
  end

  describe ".validate!" do
    it "passes with valid concurrency" do
      ENV["SIDEKIQ_CONCURRENCY"] = "5"

      expect(described_class.validate!).to be(true)
    end

    it "fails with zero concurrency" do
      ENV["SIDEKIQ_CONCURRENCY"] = "0"

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "SIDEKIQ_CONCURRENCY must be greater than zero"
      )
    end

    it "fails with negative concurrency" do
      ENV["SIDEKIQ_CONCURRENCY"] = "-1"

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "SIDEKIQ_CONCURRENCY must be greater than zero"
      )
    end
  end
end