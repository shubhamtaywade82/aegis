# frozen_string_literal: true

class PerformanceReport
  attr_reader :total_trades,
              :wins,
              :losses,
              :gross_profit,
              :gross_loss,
              :net_profit,
              :profit_factor,
              :win_rate,
              :average_trade,
              :reward_risk,
              :max_drawdown,
              :equity_curve

  def initialize(
    total_trades:,
    wins:,
    losses:,
    gross_profit:,
    gross_loss:,
    net_profit:,
    profit_factor:,
    win_rate:,
    average_trade:,
    reward_risk:,
    max_drawdown:,
    equity_curve:
  )
    @total_trades  = total_trades
    @wins          = wins
    @losses        = losses
    @gross_profit  = gross_profit
    @gross_loss    = gross_loss
    @net_profit    = net_profit
    @profit_factor = profit_factor
    @win_rate      = win_rate
    @average_trade = average_trade
    @reward_risk   = reward_risk
    @max_drawdown  = max_drawdown
    @equity_curve  = equity_curve.freeze

    freeze
  end

  def profitable?
    net_profit.positive?
  end

  def robust?(
    minimum_trades: 20,
    minimum_profit_factor: 1.0,
    maximum_drawdown: 20.0
  )
    total_trades >= minimum_trades &&
      profit_factor > minimum_profit_factor &&
      max_drawdown <= maximum_drawdown
  end

  def summary
    {
      total_trades: total_trades,
      wins: wins,
      losses: losses,
      gross_profit: gross_profit,
      gross_loss: gross_loss,
      net_profit: net_profit,
      profit_factor: profit_factor,
      win_rate: win_rate,
      average_trade: average_trade,
      reward_risk: reward_risk,
      max_drawdown: max_drawdown
    }
  end
end
