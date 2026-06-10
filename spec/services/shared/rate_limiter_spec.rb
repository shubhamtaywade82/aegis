# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shared::RateLimiter do
  subject(:limiter) { described_class.new }

  it "consumes weight" do
    expect(limiter.consume(100)).to be(true)

    expect(limiter.remaining_weight).to eq(1100)
  end

  it "raises when exceeded" do
    expect do
      limiter.consume(1_201)
    end.to raise_error(
      RateLimitError,
      "Binance request weight exceeded"
    )
  end
end