# frozen_string_literal: true

require "bigdecimal"

module Portfolio
  class RebalanceEngine
    def initialize(drift_detector: nil)
      @drift_detector = drift_detector || DriftDetector.new
    end

    def generate_orders(portfolio_snapshot, target_allocations)
      current_positions = portfolio_snapshot.positions
      equity = portfolio_snapshot.equity

      current_weights = Hash.new(BigDecimal("0.0"))
      current_positions.each do |sym, pos|
        exposure = pos.quantity * pos.mark_price
        current_weights[sym] = exposure / equity
      end

      target_weights = target_allocations.transform_keys(&:to_s)
      return [] unless @drift_detector.drift_detected?(current_weights, target_weights)

      orders = []
      all_symbols = (current_weights.keys + target_weights.keys).uniq

      all_symbols.each do |sym|
        curr_w = current_weights[sym] || BigDecimal("0.0")
        targ_w = target_weights[sym] || BigDecimal("0.0")
        diff_w = targ_w - curr_w

        next if diff_w.zero?

        target_notional = diff_w * equity
        orders << {
          symbol: sym,
          side: diff_w.positive? ? :buy : :sell,
          notional: target_notional.abs
        }
      end

      orders
    end
  end
end
