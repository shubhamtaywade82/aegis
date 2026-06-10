# frozen_string_literal: true

require "rails_helper"

RSpec.describe Settings do
  around do |example|
    original_env = ENV.to_hash

    example.run
  ensure
    ENV.replace(original_env)
  end

  describe ".env!" do
    it "returns the environment variable value" do
      ENV["TEST_KEY"] = "value"

      expect(described_class.env!("TEST_KEY")).to eq("value")
    end

    it "raises when missing" do
      ENV.delete("TEST_KEY")

      expect do
        described_class.env!("TEST_KEY")
      end.to raise_error(
        ConfigurationError,
        "Missing required environment variable: TEST_KEY"
      )
    end
  end

  describe ".integer" do
    it "returns integer values" do
      ENV["TEST_INTEGER"] = "123"

      expect(
        described_class.integer("TEST_INTEGER", 0)
      ).to eq(123)
    end

    it "raises for invalid integers" do
      ENV["TEST_INTEGER"] = "abc"

      expect do
        described_class.integer("TEST_INTEGER", 0)
      end.to raise_error(
        ConfigurationError,
        "Environment variable TEST_INTEGER must be an integer"
      )
    end
  end

  describe ".float" do
    it "returns float values" do
      ENV["TEST_FLOAT"] = "1.5"

      expect(
        described_class.float("TEST_FLOAT", 0.0)
      ).to eq(1.5)
    end

    it "raises for invalid floats" do
      ENV["TEST_FLOAT"] = "abc"

      expect do
        described_class.float("TEST_FLOAT", 0.0)
      end.to raise_error(
        ConfigurationError,
        "Environment variable TEST_FLOAT must be a float"
      )
    end
  end

  describe ".boolean" do
    it "returns true for truthy values" do
      %w[true TRUE 1 yes y on].each do |value|
        ENV["TEST_BOOL"] = value

        expect(
          described_class.boolean("TEST_BOOL")
        ).to be(true)
      end
    end

    it "returns false for falsy values" do
      ENV["TEST_BOOL"] = "false"

      expect(
        described_class.boolean("TEST_BOOL")
      ).to be(false)
    end

    it "returns default when missing" do
      ENV.delete("TEST_BOOL")

      expect(
        described_class.boolean("TEST_BOOL", true)
      ).to be(true)
    end
  end
end