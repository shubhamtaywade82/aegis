# frozen_string_literal: true

require "bigdecimal"

class ExecutionReport
  attr_reader :executed_trades,
              :gross_net_profit,
              :execution_net_profit,
              :fee_impact,
              :slippage_impact,
              :funding_impact,
              :execution_profit_factor

  def initialize(
    executed_trades:,
    gross_net_profit:,
    execution_net_profit:,
    fee_impact:,
    slippage_impact:,
    funding_impact:,
    execution_profit_factor:
  )
    @executed_trades = executed_trades.freeze
    @gross_net_profit = BigDecimal(gross_net_profit.to_s)
    @execution_net_profit = BigDecimal(execution_net_profit.to_s)
    @fee_impact = BigDecimal(fee_impact.to_s)
    @slippage_impact = BigDecimal(slippage_impact.to_s)
    @funding_impact = BigDecimal(funding_impact.to_s)
    @execution_profit_factor = BigDecimal(execution_profit_factor.to_s)

    freeze
  end

  def degradation_vs_research
    return 0.0 if gross_net_profit.zero?

    diff = gross_net_profit - execution_net_profit
    ((diff / gross_net_profit.abs) * 100.0).to_f.round(2)
  end

  def summary
    {
      gross_net_profit: gross_net_profit.to_f.round(4),
      execution_net_profit: execution_net_profit.to_f.round(4),
      fee_impact: fee_impact.to_f.round(4),
      slippage_impact: slippage_impact.to_f.round(4),
      funding_impact: funding_impact.to_f.round(4),
      execution_profit_factor: execution_profit_factor.to_f.round(4),
      degradation_vs_research: degradation_vs_research
    }
  end
end
