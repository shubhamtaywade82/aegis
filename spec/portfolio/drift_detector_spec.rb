# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/portfolio/drift_detector"

RSpec.describe Portfolio::DriftDetector do
  let(:detector) { described_class.new }

  it "detects drift when weight diff exceeds threshold (5%)" do
    curr = { "SOLUSDT" => 0.10 }
    targ = { "SOLUSDT" => 0.16 }
    expect(detector.drift_detected?(curr, targ)).to be(true)
  end

  it "does not detect drift when diff is small" do
    curr = { "SOLUSDT" => 0.10 }
    targ = { "SOLUSDT" => 0.12 }
    expect(detector.drift_detected?(curr, targ)).to be(false)
  end
end
