# frozen_string_literal: true

require "rails_helper"

RSpec.describe SidekiqSettings do
  around do |example|
    original_env = ENV.to_hash

    example.run
  ensure
    ENV.replace(original_env)
  end

  before do
    ENV["SIDEKIQ_CONCURRENCY"] = "15"
  end

  describe ".concurrency" do
    it "returns integer value" do
      expect(described_class.concurrency).to eq(15)
    end

    it "returns default when missing" do
      ENV.delete("SIDEKIQ_CONCURRENCY")

      expect(described_class.concurrency).to eq(10)
    end
  end

  describe ".validate!" do
    it "passes with valid config" do
      expect(described_class.validate!).to be(true)
    end

    it "raises when concurrency is not positive" do
      ENV["SIDEKIQ_CONCURRENCY"] = "0"

      expect do
        described_class.validate!
      end.to raise_error(
        ConfigurationError,
        "SIDEKIQ_CONCURRENCY must be greater than 0"
      )
    end
  end
end