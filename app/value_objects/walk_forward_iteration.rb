# frozen_string_literal: true

class WalkForwardIteration
  attr_reader :optimization_start,
              :optimization_end,
              :forward_start,
              :forward_end,
              :stable_region,
              :performance_report

  def initialize(
    optimization_start:,
    optimization_end:,
    forward_start:,
    forward_end:,
    stable_region:,
    performance_report:
  )
    @optimization_start = optimization_start
    @optimization_end   = optimization_end
    @forward_start      = forward_start
    @forward_end        = forward_end
    @stable_region      = stable_region
    @performance_report = performance_report

    freeze
  end

  delegate :net_profit,
           :profit_factor,
           :win_rate,
           :total_trades,
           :max_drawdown,
           to: :performance_report

  def summary
    {
      optimization_range: "#{optimization_start}-#{optimization_end}",
      forward_range: "#{forward_start}-#{forward_end}",
      length: stable_region.length,
      multiplier: stable_region.multiplier,
      profit_factor: profit_factor,
      net_profit: net_profit,
      win_rate: win_rate,
      total_trades: total_trades,
      max_drawdown: max_drawdown
    }
  end
end
