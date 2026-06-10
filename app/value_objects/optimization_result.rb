# frozen_string_literal: true

class OptimizationResult
  attr_reader :length,
              :multiplier,
              :performance_report

  def initialize(
    length:,
    multiplier:,
    performance_report:
  )
    @length = length
    @multiplier = multiplier
    @performance_report = performance_report

    freeze
  end

  delegate :profit_factor,
           :net_profit,
           :win_rate,
           :max_drawdown,
           :total_trades,
           to: :performance_report

  def valid?(minimum_trades: 20)
    total_trades >= minimum_trades
  end

  def summary
    {
      length: length,
      multiplier: multiplier,
      profit_factor: profit_factor,
      net_profit: net_profit,
      win_rate: win_rate,
      max_drawdown: max_drawdown,
      total_trades: total_trades
    }
  end
end
