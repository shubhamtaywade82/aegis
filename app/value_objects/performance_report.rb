# frozen_string_literal: true

class PerformanceReport
  attr_reader :trades,
              :wins,
              :losses,
              :gross_profit,
              :gross_loss,
              :net_profit,
              :profit_factor,
              :win_rate,
              :average_trade,
              :reward_risk,
              :max_drawdown

  def initialize(
    trades:,
    wins:,
    losses:,
    gross_profit:,
    gross_loss:,
    net_profit:,
    profit_factor:,
    win_rate:,
    average_trade:,
    reward_risk:,
    max_drawdown:
  )
    @trades = trades.freeze
    @wins = wins
    @losses = losses
    @gross_profit = gross_profit
    @gross_loss = gross_loss
    @net_profit = net_profit
    @profit_factor = profit_factor
    @win_rate = win_rate
    @average_trade = average_trade
    @reward_risk = reward_risk
    @max_drawdown = max_drawdown
    freeze
  end

  def profitable?
    net_profit.positive?
  end

  def robust?
    profit_factor > 1.0 && trades.size >= 20
  end

  def summary
    {
      net_profit: net_profit,
      profit_factor: profit_factor,
      win_rate: win_rate,
      trade_count: trades.size,
      max_drawdown: max_drawdown
    }
  end
end
