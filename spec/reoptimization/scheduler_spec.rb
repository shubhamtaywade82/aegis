# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reoptimization::Scheduler do
  let(:active_model) do
    TradingModel.new(
      version: "v17",
      length: 10,
      multiplier: 1.5,
      confidence: 87.2,
      execution_pf: 1.35,
      status: :active
    )
  end

  let(:scheduler) { described_class.new(active_model: active_model) }

  describe "#retrain!" do
    it "creates a candidate and sets to shadow status if valid" do
      res = scheduler.retrain!(
        new_version: "v18",
        length: 11,
        multiplier: 1.4,
        confidence: 91.3,
        execution_pf: 1.52
      )
      expect(res).to be(true)
      expect(scheduler.candidate_model).not_to be_nil
      expect(scheduler.candidate_model.status).to eq(:shadow)
    end

    it "rejects candidate if confidence is below 80" do
      res = scheduler.retrain!(
        new_version: "v18",
        length: 11,
        multiplier: 1.4,
        confidence: 75.0,
        execution_pf: 1.52
      )
      expect(res).to be(false)
      expect(scheduler.candidate_model).to be_nil
    end
  end

  describe "#record_shadow_trade" do
    before do
      scheduler.retrain!(
        new_version: "v18",
        length: 11,
        multiplier: 1.4,
        confidence: 91.3,
        execution_pf: 1.52
      )
    end

    it "tracks trades and computes win rate difference" do
      scheduler.record_shadow_trade(candidate_won: true, active_won: false)
      scheduler.record_shadow_trade(candidate_won: true, active_won: true)

      expect(scheduler.shadow_trades_count).to eq(2)
      expect(scheduler.shadow_win_rate_difference).to eq(0.5)
    end
  end

  describe "#promote_candidate!" do
    before do
      scheduler.retrain!(
        new_version: "v18",
        length: 11,
        multiplier: 1.4,
        confidence: 91.3,
        execution_pf: 1.52
      )
    end

    it "rejects promotion before 50 trades" do
      scheduler.approve_promotion_request!
      res = scheduler.promote_candidate!
      expect(res[:success]).to be(false)
      expect(res[:reason]).to include("Insufficient shadow trade count")
    end

    it "rejects promotion without user approval" do
      50.times { scheduler.record_shadow_trade(candidate_won: true, active_won: true) }
      res = scheduler.promote_candidate!
      expect(res[:success]).to be(false)
      expect(res[:reason]).to include("Awaiting Telegram user approval")
    end

    it "promotes candidate when all conditions are met" do
      50.times { scheduler.record_shadow_trade(candidate_won: true, active_won: true) }
      scheduler.approve_promotion_request!

      res = scheduler.promote_candidate!
      expect(res[:success]).to be(true)
      expect(scheduler.active_model.version).to eq("v18")
      expect(scheduler.active_model.status).to eq(:active)
    end
  end

  describe "#check_for_rollback!" do
    it "triggers rollback on drawdown violation" do
      res = scheduler.check_for_rollback!(live_pf: 1.2, drawdown: 11.0)
      expect(res).to be(true)
      expect(active_model.status).to eq(:rolled_back)
    end
  end
end
