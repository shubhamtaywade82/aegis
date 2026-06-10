# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/ai/provider_router"
require_relative "../../app/ai/validator"
require_relative "../../app/value_objects/order_request"

RSpec.describe AI::Validator do
  let(:router) { AI::ProviderRouter.new(provider: :simulated) }
  let(:validator) { described_class.new(provider_router: router) }
  let(:order_request) do
    OrderRequest.new(
      symbol: "SOLUSDT",
      side: :buy,
      quantity: 10.0,
      order_type: :market
    )
  end

  it "validates order setups returning structured JSON data" do
    data = validator.validate_setup(
      order_request: order_request,
      indicators: { rsi: 62 }
    )
    expect(data[:advisory_score]).to eq(85)
    expect(data[:approved]).to be(true)
    expect(data[:concerns].first).to include("Funding rate")
  end
end
