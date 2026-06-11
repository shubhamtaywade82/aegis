# frozen_string_literal: true

require "bigdecimal"

module Capital
  class CapitalEngine
    attr_reader :exchange_budgets, :growth_scaler

    def initialize(exchange_budgets: {}, base_risk_pct: BigDecimal("0.005"))
      @exchange_budgets = exchange_budgets.transform_keys(&:to_sym)
      @growth_scaler = Portfolio::GrowthScaler.new(base_risk_pct: base_risk_pct)
    end

    def calculate_risk_budget(exchange:, wallet_snapshot:, drawdown_pct:, equity_change_pct:)
      available = wallet_snapshot.total_equity - wallet_snapshot.used_margin - wallet_snapshot.reserved_margin
      available = [ available, BigDecimal("0.0") ].max

      budget_pct = BigDecimal((exchange_budgets[exchange.to_sym] || 1.0).to_s)
      allocatable = available * budget_pct

      risk_pct = growth_scaler.scale_risk(
        drawdown_pct: drawdown_pct,
        equity_change_pct: equity_change_pct
      )

      (allocatable * risk_pct).round(8)
    end
  end
end
