# frozen_string_literal: true

module Live
  class RolloutManager
    attr_reader :stage, :trades_count, :risk_failures, :reconciliation_failures, :drawdown, :pf

    STAGES = [ :canary, :controlled, :standard ].freeze

    def initialize(stage: :canary)
      @stage = stage.to_sym
      @trades_count = 0
      @risk_failures = 0
      @reconciliation_failures = 0
      @drawdown = 0.0
      @pf = 1.0
    end

    def profile
      case stage
      when :canary
        {
          risk_per_trade: 0.0025,
          daily_loss: 0.01,
          max_positions: 1,
          max_leverage: 2
        }
      when :controlled
        {
          risk_per_trade: 0.0050,
          daily_loss: 0.02,
          max_positions: 2,
          max_leverage: 3
        }
      when :standard
        {
          risk_per_trade: 0.0050,
          daily_loss: 0.03,
          max_positions: 3,
          max_leverage: 5
        }
      end
    end

    def update_metrics!(trades_count:, pf:, drawdown:, risk_failures: 0, reconciliation_failures: 0)
      @trades_count = trades_count
      @pf = pf
      @drawdown = drawdown
      @risk_failures = risk_failures
      @reconciliation_failures = reconciliation_failures

      check_for_rollback
    end

    def promote!
      case stage
      when :canary
        if trades_count >= 30 && pf > 1.20 && risk_failures.zero? && reconciliation_failures.zero?
          @stage = :controlled
          true
        else
          false
        end
      when :controlled
        if trades_count >= 100 && pf > 1.25 && drawdown < 5.0 && risk_failures.zero? && reconciliation_failures.zero?
          @stage = :standard
          true
        else
          false
        end
      else
        false
      end
    end

    private

    def check_for_rollback
      if pf < 1.0 || drawdown > 10.0 || risk_failures.positive? || reconciliation_failures.positive?
        @stage = :canary
      end
    end
  end
end
