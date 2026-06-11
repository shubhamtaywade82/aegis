# frozen_string_literal: true

require "rails_helper"
require_relative "../support/fixture_paths"
require_relative "../support/fixture_loader"

RSpec.describe Research::Optimizer do
  let(:series) do
    FixtureLoader.load_binance_fixture(
      FixturePaths.binance(
        "SOLUSDT_1h_sample.json"
      )
    )
  end

  describe ".call" do
    subject(:results) do
      described_class.call(
        candles: series
      )
    end

    it "returns 100 optimization results" do
      expect(results.size).to eq(100)
    end

    it "returns OptimizationResult objects" do
      expect(
        results.all? { |r| r.is_a?(OptimizationResult) }
      ).to be(true)
    end

    it "evaluates all length variants" do
      lengths =
        results.map(&:length).uniq.sort

      expect(lengths).to eq((5..14).to_a)
    end

    it "evaluates all multiplier variants" do
      multipliers =
        results.map(&:multiplier).uniq.sort

      expect(multipliers).to eq(
        [
          1.0,
          1.1,
          1.2,
          1.3,
          1.4,
          1.5,
          1.6,
          1.7,
          1.8,
          1.9
        ]
      )
    end
  end
end
