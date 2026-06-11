# frozen_string_literal: true

require "bigdecimal"

module Execution
  class MetricsEngine
    def self.calculate(closed_trades:, initial_balance:, current_equity:, max_drawdown:)
      new(
        closed_trades: closed_trades,
        initial_balance: initial_balance,
        current_equity: current_equity,
        max_drawdown: max_drawdown
      ).calculate
    end

    attr_reader :closed_trades,
                :initial_balance,
                :current_equity,
                :max_drawdown

    def initialize(closed_trades:, initial_balance:, current_equity:, max_drawdown:)
      @closed_trades = closed_trades
      @initial_balance = BigDecimal(initial_balance.to_s)
      @current_equity = BigDecimal(current_equity.to_s)
      @max_drawdown = BigDecimal(max_drawdown.to_s)
    end

    def calculate
      {
        win_rate: win_rate,
        profit_factor: profit_factor,
        average_trade: average_trade,
        expectancy: expectancy,
        max_drawdown: max_drawdown.to_f.round(4),
        sharpe_ratio: sharpe_ratio,
        recovery_factor: recovery_factor
      }
    end

    private

    def total_trades
      closed_trades.size
    end

    def winning_trades
      closed_trades.select { |t| t.realized_pnl.positive? }
    end

    def losing_trades
      closed_trades.select { |t| t.realized_pnl.negative? }
    end

    def win_rate
      return 0.0 if total_trades.zero?

      ((winning_trades.size.to_f / total_trades) * 100.0).round(2)
    end

    def profit_factor
      gross_profit = winning_trades.sum(&:realized_pnl)
      gross_loss = losing_trades.sum { |t| t.realized_pnl.abs }

      return 0.0 if gross_profit.zero? && gross_loss.zero?
      return 10_000.0 if gross_loss.zero?

      (gross_profit / gross_loss).to_f.round(4)
    end

    def average_trade
      return 0.0 if total_trades.zero?

      total_pnl = closed_trades.sum(&:realized_pnl)
      (total_pnl / total_trades).to_f.round(4)
    end

    def expectancy
      return 0.0 if total_trades.zero?

      win_prob = winning_trades.size.to_f / total_trades
      loss_prob = losing_trades.size.to_f / total_trades

      avg_win = winning_trades.empty? ? BigDecimal("0.0") : (winning_trades.sum(&:realized_pnl) / winning_trades.size)
      avg_loss = losing_trades.empty? ? BigDecimal("0.0") : (losing_trades.sum { |t| t.realized_pnl.abs } / losing_trades.size)

      ((win_prob * avg_win) - (loss_prob * avg_loss)).to_f.round(4)
    end

    def sharpe_ratio
      return 0.0 if total_trades < 2

      pnls = closed_trades.map { |t| t.realized_pnl.to_f }
      mean = pnls.sum / pnls.size
      variance = pnls.sum { |p| (p - mean)**2 } / (pnls.size - 1)
      std_dev = Math.sqrt(variance)

      return 0.0 if std_dev.zero?

      (mean / std_dev).round(4)
    end

    def recovery_factor
      return 0.0 if max_drawdown.zero?

      net_profit = current_equity - initial_balance
      (net_profit / max_drawdown).to_f.round(4)
    end
  end
end
