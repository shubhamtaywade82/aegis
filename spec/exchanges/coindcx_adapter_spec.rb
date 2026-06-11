# frozen_string_literal: true

require "rails_helper"
require_relative "../support/shared_exchange_adapter"

RSpec.describe Exchanges::CoinDCX::Adapter do
  let(:adapter) { described_class.new(api_key: "test_key", api_secret: "test_secret") }

  include_examples "exchange adapter"

  it "returns CoinDCX specific capabilities" do
    expect(adapter.capabilities[:hedge_mode]).to be(false)
    expect(adapter.capabilities[:bracket_orders]).to be(false)
  end
end
