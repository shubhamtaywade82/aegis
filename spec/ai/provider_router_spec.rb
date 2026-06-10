# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/ai/provider_router"

RSpec.describe AI::ProviderRouter do
  let(:router) { described_class.new(provider: :simulated) }

  it "returns simulated response in testing mode" do
    res = router.generate("test prompt")
    expect(res).to include("Simulated response")
  end
end
