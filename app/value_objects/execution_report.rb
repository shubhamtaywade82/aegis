# frozen_string_literal: true

class ExecutionReport
  attr_reader :executed_trades,
              :research_net_profit,
              :execution_net_profit,
              :fee_impact,
              :funding_impact,
              :slippage_impact,
              :research_profit_factor,
              :execution_profit_factor

  def initialize(
    executed_trades:,
    research_net_profit:,
    execution_net_profit:,
    fee_impact:,
    funding_impact:,
    slippage_impact:,
    research_profit_factor:,
    execution_profit_factor:
  )
    @executed_trades = executed_trades.freeze

    @research_net_profit = research_net_profit
    @execution_net_profit = execution_net_profit

    @fee_impact = fee_impact
    @funding_impact = funding_impact
    @slippage_impact = slippage_impact

    @research_profit_factor = research_profit_factor
    @execution_profit_factor = execution_profit_factor

    freeze
  end

  def degradation_percentage
    return 0.0 if research_net_profit.zero?

    (
      (
        research_net_profit -
        execution_net_profit
      ) /
      research_net_profit.abs
    ) * 100.0
  end

  def execution_ready?
    execution_profit_factor > 1.2 &&
      degradation_percentage < 20.0
  end

  def summary
    {
      research_net_profit: research_net_profit,
      execution_net_profit: execution_net_profit,

      fee_impact: fee_impact,
      funding_impact: funding_impact,
      slippage_impact: slippage_impact,

      research_profit_factor: research_profit_factor,
      execution_profit_factor: execution_profit_factor,

      degradation_percentage: degradation_percentage.round(2),

      execution_ready: execution_ready?
    }
  end
end
