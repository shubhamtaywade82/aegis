# frozen_string_literal: true

require_relative "../value_objects/performance_report"

module Research
  class MetricsCalculator
    attr_reader :trades

    def initialize(trades)
      @trades = trades.freeze
    end

    def call
      PerformanceReport.new(
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
        max_drawdown: max_drawdown,
        equity_curve: equity_curve,
        trades: trades
      )
    end

    private

    def total_trades
      trades.size
    end

    def winning_trades
      @winning_trades ||= trades.select(&:winner?)
    end

    def losing_trades
      @losing_trades ||= trades.select(&:loser?)
    end

    def wins
      winning_trades.size
    end

    def losses
      losing_trades.size
    end

    def gross_profit
      winning_trades.sum(&:pnl).round(8)
    end

    def gross_loss
      losing_trades.sum { |trade| trade.pnl.abs }.round(8)
    end

    def net_profit
      trades.sum(&:pnl).round(8)
    end

    def profit_factor
      return 0.0 if gross_profit.zero? && gross_loss.zero?

      return 10_000.0 if gross_loss.zero?

      (gross_profit / gross_loss).round(4)
    end

    def win_rate
      return 0.0 if total_trades.zero?

      ((wins.to_f / total_trades) * 100.0).round(2)
    end

    def average_trade
      return 0.0 if total_trades.zero?

      (net_profit / total_trades).round(8)
    end

    def reward_risk
      return 0.0 if wins.zero?
      return 10_000.0 if losses.zero?

      average_win = gross_profit / wins
      average_loss = gross_loss / losses

      return 0.0 if average_loss.zero? && average_win.zero?
      return 10_000.0 if average_loss.zero?

      (average_win / average_loss).round(4)
    end

    def equity_curve
      @equity_curve ||= begin
        equity = 0.0

        trades.map do |trade|
          equity += trade.pnl
          equity.round(8)
        end.freeze
      end
    end

    def max_drawdown
      return 0.0 if equity_curve.empty?

      peak = equity_curve.first
      maximum_drawdown = 0.0

      equity_curve.each do |equity|
        peak = [ peak, equity ].max
        drawdown = peak - equity
        maximum_drawdown = [ maximum_drawdown, drawdown ].max
      end

      maximum_drawdown.round(8)
    end
  end
end
