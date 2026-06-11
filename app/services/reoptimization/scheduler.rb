# frozen_string_literal: true

require "bigdecimal"

module Reoptimization
  class Scheduler
    attr_reader :active_model, :candidate_model, :shadow_trades_count, :candidate_wins, :candidate_losses, :active_wins, :active_losses, :approved_by_user

    def initialize(active_model:)
      @active_model = active_model
      @candidate_model = nil
      @shadow_trades_count = 0
      @candidate_wins = 0
      @candidate_losses = 0
      @active_wins = 0
      @active_losses = 0
      @approved_by_user = false
    end

    def check_and_run!(current_time)
      true
    end

    def retrain!(new_version:, length:, multiplier:, confidence:, execution_pf:)
      candidate = TradingModel.new(
        version: new_version,
        length: length,
        multiplier: multiplier,
        confidence: confidence,
        execution_pf: execution_pf,
        status: :candidate
      )

      if candidate.confidence >= BigDecimal("80.0") &&
         candidate.execution_pf >= BigDecimal("1.20")
        @candidate_model = candidate
        candidate.shadow!
        true
      else
        false
      end
    end

    def record_shadow_trade(candidate_won:, active_won:)
      return unless candidate_model&.shadow?

      @shadow_trades_count += 1
      if candidate_won
        @candidate_wins += 1
      else
        @candidate_losses += 1
      end

      if active_won
        @active_wins += 1
      else
        @active_losses += 1
      end
    end

    def shadow_win_rate_difference
      return 0.0 if shadow_trades_count.zero?
      candidate_wr = @candidate_wins.to_f / shadow_trades_count.to_f
      active_wr = @active_wins.to_f / shadow_trades_count.to_f
      (candidate_wr - active_wr).round(4)
    end

    def approve_promotion_request!
      @approved_by_user = true
    end

    def promote_candidate!
      return { success: false, reason: "No candidate model in shadow mode" } unless candidate_model&.shadow?
      return { success: false, reason: "Awaiting Telegram user approval" } unless approved_by_user

      if shadow_trades_count < 50
        return { success: false, reason: "Insufficient shadow trade count: #{shadow_trades_count} < 50" }
      end

      if candidate_model.confidence < active_model.confidence
        return { success: false, reason: "Candidate confidence is lower than active model" }
      end

      old_active = @active_model
      old_active.deactivate!

      @active_model = candidate_model
      @active_model.activate!
      @candidate_model = nil
      @approved_by_user = false

      { success: true, old_version: old_active.version, new_version: @active_model.version }
    end

    def check_for_rollback!(live_pf:, drawdown:)
      if live_pf < 1.0 || drawdown > 10.0
        @active_model.rollback!
        true
      else
        false
      end
    end
  end
end
