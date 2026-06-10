# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParameterSet do
  it "validates parameter sets" do
    params = described_class.new(
      length: 10,
      multiplier: 2.0,
      stable_score: 1.5,
      profit_factor: 1.8,
      trade_count: 25
    )

    expect(params.valid?).to be(true)
    expect(params.identifier).to eq("10-2.0")
  end
end
