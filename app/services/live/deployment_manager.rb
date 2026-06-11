# frozen_string_literal: true


module Live
  class DeploymentManager
    attr_reader :feature_flags, :rollout_manager, :approval_engine, :divergence_monitor

    def initialize(flags: {}, stage: :canary)
      @feature_flags = FeatureFlags.new(flags)
      @rollout_manager = RolloutManager.new(stage: stage)
      @approval_engine = ApprovalEngine.new
      @divergence_monitor = DivergenceMonitor.new
    end

    def process_order(order_request)
      unless feature_flags.enabled?(:live_trading_enabled)
        return { action: :reject, reason: "Live trading disabled" }
      end

      if rollout_manager.stage == :canary && !feature_flags.enabled?(:auto_execution_enabled)
        approval_id = approval_engine.request_approval(order_request)
        return { action: :hold, approval_id: approval_id, reason: "Awaiting manual confirmation" }
      end

      { action: :execute }
    end
  end
end
