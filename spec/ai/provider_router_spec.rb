# frozen_string_literal: true

require "rails_helper"

RSpec.describe AI::ProviderRouter do
  let(:router) { described_class.new(provider: :simulated) }

  it "returns simulated response in testing mode" do
    res = router.generate("test prompt")
    expect(res).to include("Simulated response")
  end
end
