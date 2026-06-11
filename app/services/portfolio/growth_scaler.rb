# frozen_string_literal: true

require "bigdecimal"

module Portfolio
  class GrowthScaler
    attr_reader :base_risk_pct

    def initialize(base_risk_pct: BigDecimal("0.005"))
      @base_risk_pct = BigDecimal(base_risk_pct.to_s)
    end

    def scale_risk(drawdown_pct:, equity_change_pct:)
      if drawdown_pct >= 10.0
        return BigDecimal("0.0")
      elsif drawdown_pct >= 5.0
        return base_risk_pct * BigDecimal("0.5")
      end

      risk = base_risk_pct
      if equity_change_pct >= 20.0
        risk *= BigDecimal("1.10")
      elsif equity_change_pct <= -10.0
        risk *= BigDecimal("0.50")
      end

      risk.round(6)
    end
  end
end
