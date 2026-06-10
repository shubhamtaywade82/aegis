# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/ai/provider_router"
require_relative "../../app/ai/journal_analyzer"
require_relative "../../app/value_objects/closed_trade"

RSpec.describe Ai::JournalAnalyzer do
  let(:router) { Ai::ProviderRouter.new(provider: :simulated) }
  let(:analyzer) { described_class.new(provider_router: router) }
  let(:closed_trade) do
    ClosedTrade.new(
      entry_price: 150.0,
      exit_price: 160.0,
      quantity: 10.0,
      fees: 1.0,
      realized_pnl: 99.0,
      holding_period: 3600,
      exit_reason: "take_profit"
    )
  end

  it "analyzes closed trades journal" do
    res = analyzer.analyze_trades([ closed_trade ])
    expect(res).to include("Simulated analysis")
    expect(res).to include("win rate")
  end
end
