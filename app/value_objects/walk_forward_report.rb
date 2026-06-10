# frozen_string_literal: true

class WalkForwardReport
  attr_reader :iterations

  def initialize(iterations:)
    @iterations = iterations.freeze

    freeze
  end

  def total_iterations
    iterations.size
  end

  def total_net_profit
    iterations.sum(&:net_profit)
  end

  def average_profit_factor
    return 0.0 if iterations.empty?

    iterations.sum(&:profit_factor) /
      iterations.size.to_f
  end

  def average_win_rate
    return 0.0 if iterations.empty?

    iterations.sum(&:win_rate) /
      iterations.size.to_f
  end

  def worst_drawdown
    iterations.map(&:max_drawdown)
              .max || 0.0
  end

  def summary
    {
      total_iterations: total_iterations,
      total_net_profit: total_net_profit.round(4),
      average_profit_factor: average_profit_factor.round(4),
      average_win_rate: average_win_rate.round(2),
      worst_drawdown: worst_drawdown.round(2)
    }
  end
end
