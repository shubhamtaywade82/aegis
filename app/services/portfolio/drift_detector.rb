# frozen_string_literal: true

require "bigdecimal"

module Portfolio
  class DriftDetector
    REBALANCE_THRESHOLD = BigDecimal("0.05")

    def initialize(threshold: REBALANCE_THRESHOLD)
      @threshold = BigDecimal(threshold.to_s)
    end

    def drift_detected?(current_allocations, target_allocations)
      all_symbols = (current_allocations.keys + target_allocations.keys).uniq

      all_symbols.each do |sym|
        curr = BigDecimal((current_allocations[sym] || 0.0).to_s)
        targ = BigDecimal((target_allocations[sym] || 0.0).to_s)
        drift = (curr - targ).abs
        return true if drift > @threshold
      end

      false
    end
  end
end
