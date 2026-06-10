# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/ai/provider_router"
require_relative "../../app/ai/narrative_generator"

RSpec.describe Ai::NarrativeGenerator do
  let(:router) { Ai::ProviderRouter.new(provider: :simulated) }
  let(:generator) { described_class.new(provider_router: router) }

  it "generates a narrative for the setup context" do
    res = generator.build_narrative(
      symbol: "SOLUSDT",
      side: :buy,
      entry_price: 150.0,
      stop_loss: 145.0,
      take_profit: 160.0
    )
    expect(res).to include("Simulated narrative")
    expect(res).to include("SOLUSDT")
  end
end
