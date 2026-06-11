# frozen_string_literal: true

module Live
  class FeatureFlags
    def initialize(flags = {})
      @flags = {
        live_trading_enabled: false,
        auto_execution_enabled: false,
        allow_shorts: false,
        allow_pyramiding: false,
        allow_reversals: false,
        auto_reoptimization: false,
        panic_flatten_enabled: true
      }.merge(flags.transform_keys(&:to_sym))
    end

    def enabled?(flag)
      !!@flags[flag.to_sym]
    end

    def set!(flag, value)
      @flags[flag.to_sym] = !!value
    end
  end
end
