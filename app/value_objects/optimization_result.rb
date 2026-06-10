# frozen_string_literal: true

class OptimizationResult
  attr_reader :symbol,
              :interval,
              :optimize_from,
              :optimize_to,
              :forward_from,
              :forward_to,
              :parameter_set,
              :net_profit,
              :profit_factor,
              :win_rate,
              :trade_count,
              :max_drawdown

  def initialize(
    symbol:,
    interval:,
    optimize_from:,
    optimize_to:,
    forward_from:,
    forward_to:,
    parameter_set:,
    net_profit:,
    profit_factor:,
    win_rate:,
    trade_count:,
    max_drawdown:
  )
    @symbol = symbol
    @interval = interval
    @optimize_from = optimize_from
    @optimize_to = optimize_to
    @forward_from = forward_from
    @forward_to = forward_to
    @parameter_set = parameter_set
    @net_profit = net_profit
    @profit_factor = profit_factor
    @win_rate = win_rate
    @trade_count = trade_count
    @max_drawdown = max_drawdown
    freeze
  end

  def profitable?
    net_profit.positive?
  end

  def robust?
    profit_factor > 1.0 &&
      parameter_set.valid?
  end

  def summary
    {
      symbol: symbol,
      interval: interval,
      profit_factor: profit_factor,
      net_profit: net_profit,
      win_rate: win_rate,
      trade_count: trade_count,
      max_drawdown: max_drawdown,
      parameter: parameter_set.identifier
    }
  end
end
