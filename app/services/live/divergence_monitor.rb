# frozen_string_literal: true

require "bigdecimal"

module Live
  class DivergenceMonitor
    attr_reader :slippages, :total_expected_pnl, :total_actual_pnl

    def initialize
      @slippages = []
      @total_expected_pnl = BigDecimal("0.0")
      @total_actual_pnl = BigDecimal("0.0")
    end

    def record_fill(expected_price:, actual_price:)
      expected = BigDecimal(expected_price.to_s)
      actual = BigDecimal(actual_price.to_s)
      return if expected.zero?

      slippage = ((actual - expected) / expected).abs
      @slippages << slippage
      slippage
    end

    def record_pnl(expected_pnl:, actual_pnl:)
      @total_expected_pnl += BigDecimal(expected_pnl.to_s)
      @total_actual_pnl += BigDecimal(actual_pnl.to_s)
    end

    def average_slippage
      return 0.0 if @slippages.empty?
      (@slippages.sum / BigDecimal(@slippages.size.to_s)).to_f.round(6)
    end

    def pnl_drift
      return 0.0 if @total_expected_pnl.zero?
      ((@total_actual_pnl - @total_expected_pnl) / @total_expected_pnl).to_f.round(4)
    end
  end
end
