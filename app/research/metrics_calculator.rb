# frozen_string_literal: true

require_relative "../value_objects/performance_report"

module Research
  module MetricsCalculator
    module_function

    def calculate(trades)
      return empty_report(trades) if trades.empty?

      # Group wins and losses
      winning_trades, losing_trades = trades.partition(&:winner?)

      wins = winning_trades.size
      losses = losing_trades.size

      gross_profit = winning_trades.sum(&:pnl).to_f
      gross_loss = losing_trades.sum { |t| t.pnl.abs }.to_f

      net_profit = gross_profit - gross_loss

      profit_factor =
        if gross_loss.zero?
          gross_profit.positive? ? Float::INFINITY : 0.0
        else
          gross_profit / gross_loss
        end

      win_rate = (wins.to_f / trades.size) * 100.0
      average_trade = net_profit / trades.size

      # Reward/Risk: average win / average loss
      avg_win = wins.positive? ? (gross_profit / wins) : 0.0
      avg_loss = losses.positive? ? (gross_loss / losses) : 0.0
      reward_risk = avg_loss.zero? ? avg_win : avg_win / avg_loss

      # Max Drawdown
      equity = 0.0
      peak = 0.0
      max_drawdown = 0.0

      # Sort by exit time to reconstruct equity curve sequence
      sorted_trades = trades.sort_by(&:exit_time)
      sorted_trades.each do |trade|
        equity += trade.pnl
        peak = equity if equity > peak
        dd = peak - equity
        max_drawdown = dd if dd > max_drawdown
      end

      PerformanceReport.new(
        trades: trades,
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
      )
    end

    def empty_report(trades)
      PerformanceReport.new(
        trades: trades,
        wins: 0,
        losses: 0,
        gross_profit: 0.0,
        gross_loss: 0.0,
        net_profit: 0.0,
        profit_factor: 0.0,
        win_rate: 0.0,
        average_trade: 0.0,
        reward_risk: 0.0,
        max_drawdown: 0.0
      )
    end
  end
end
