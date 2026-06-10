# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/live/rollout_manager"

RSpec.describe Live::RolloutManager do
  let(:manager) { described_class.new(stage: :canary) }

  it "loads the initial profile" do
    prof = manager.profile
    expect(prof[:max_positions]).to eq(1)
    expect(prof[:max_leverage]).to eq(2)
  end

  it "promotes after satisfying canary requirements" do
    manager.update_metrics!(trades_count: 35, pf: 1.3, drawdown: 2.0)
    promoted = manager.promote!
    expect(promoted).to be(true)
    expect(manager.stage).to eq(:controlled)
  end

  it "fails promotion if trades count is insufficient" do
    manager.update_metrics!(trades_count: 20, pf: 1.3, drawdown: 2.0)
    promoted = manager.promote!
    expect(promoted).to be(false)
    expect(manager.stage).to eq(:canary)
  end

  it "rolls back to canary if metrics degrade" do
    manager.update_metrics!(trades_count: 35, pf: 1.3, drawdown: 2.0)
    manager.promote!
    expect(manager.stage).to eq(:controlled)

    manager.update_metrics!(trades_count: 40, pf: 0.9, drawdown: 12.0)
    expect(manager.stage).to eq(:canary)
  end
end
