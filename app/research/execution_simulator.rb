# frozen_string_literal: true

require "bigdecimal"
require_relative "../value_objects/executed_trade"
require_relative "../value_objects/execution_report"
require_relative "../indicators/atr"

module Research
  class ExecutionSimulator
    def self.call(
      trades:,
      fee_model:,
      slippage_model:,
      funding_model:,
      latency_model: nil,
      candles: nil,
      interval_seconds: 3600
    )
      new(
        trades: trades,
        fee_model: fee_model,
        slippage_model: slippage_model,
        funding_model: funding_model,
        latency_model: latency_model,
        candles: candles,
        interval_seconds: interval_seconds
      ).call
    end

    attr_reader :trades,
                :fee_model,
                :slippage_model,
                :funding_model,
                :latency_model,
                :candles,
                :interval_seconds

    def initialize(
      trades:,
      fee_model:,
      slippage_model:,
      funding_model:,
      latency_model: nil,
      candles: nil,
      interval_seconds: 3600
    )
      @trades = trades
      @fee_model = fee_model
      @slippage_model = slippage_model
      @funding_model = funding_model
      @latency_model = latency_model
      @candles = candles
      @interval_seconds = interval_seconds
    end

    def call
      executed = trades.map do |trade|
        simulate_trade(trade)
      end

      build_report(executed)
    end

    private

    def simulate_trade(trade)
      entry_price = BigDecimal(trade.entry_price.to_s)
      exit_price = BigDecimal(trade.exit_price.to_s)

      if latency_model && candles
        entry_idx = find_candle_index(trade.entry_time)
        exit_idx = find_candle_index(trade.exit_time)

        if entry_idx && exit_idx
          delayed_entry_idx = latency_model.delayed_index(
            entry_idx,
            interval_seconds: interval_seconds,
            max_index: candles.size - 1
          )
          delayed_exit_idx = latency_model.delayed_index(
            exit_idx,
            interval_seconds: interval_seconds,
            max_index: candles.size - 1
          )

          entry_price = BigDecimal(candles[delayed_entry_idx].open.to_s)
          exit_price = BigDecimal(candles[delayed_exit_idx].close.to_s)
        end
      end

      # For ATR-based slippage, calculate ATR
      atr_at_entry = nil
      if slippage_model.mode == :atr && candles
        atr_at_entry = find_atr_at_time(trade.entry_time)
      end

      executed_entry = slippage_model.apply(
        price: entry_price,
        side: trade.side,
        transaction_type: :entry,
        atr: atr_at_entry
      )

      executed_exit = slippage_model.apply(
        price: exit_price,
        side: trade.side,
        transaction_type: :exit,
        atr: atr_at_entry
      )

      qty = BigDecimal(trade.quantity.to_s)
      entry_notional = executed_entry * qty
      exit_notional = executed_exit * qty

      # Slippage cost calculation
      original_pnl = calculate_pnl(
        side: trade.side,
        entry: entry_price,
        exit: exit_price,
        qty: qty
      )
      slippage_pnl = calculate_pnl(
        side: trade.side,
        entry: executed_entry,
        exit: executed_exit,
        qty: qty
      )
      slippage_cost = original_pnl - slippage_pnl

      # Fee calculation
      fees = fee_model.calculate(
        entry_notional: entry_notional,
        exit_notional: exit_notional
      )

      # Funding calculation
      duration = trade.duration_seconds
      funding = funding_model.cost(
        notional: entry_notional,
        duration_seconds: duration
      )

      # Executed PnL
      executed_pnl = slippage_pnl - fees - funding

      ExecutedTrade.new(
        original_trade: trade,
        executed_entry_price: executed_entry,
        executed_exit_price: executed_exit,
        slippage_cost: slippage_cost,
        fee_cost: fees,
        funding_cost: funding,
        executed_pnl: executed_pnl
      )
    end

    def calculate_pnl(side:, entry:, exit:, qty:)
      case side.to_sym
      when :long
        (exit - entry) * qty
      when :short
        (entry - exit) * qty
      else
        raise ArgumentError, "Invalid side: #{side}"
      end
    end

    def find_candle_index(time)
      return nil if candles.nil?
      candles.find_index { |c| c.open_time >= time }
    end

    def find_atr_at_time(time)
      return nil if candles.nil?
      # Calculate ATR for the candles series
      atr = Indicators::ATR.calculate(candles: candles, period: 14)
      idx = find_candle_index(time)
      idx ? atr[idx] : nil
    end

    def build_report(executed_trades)
      gross_net_profit = trades.sum(&:pnl)
      execution_net_profit = executed_trades.sum(&:executed_pnl)

      fee_impact = executed_trades.sum(&:fee_cost)
      slippage_impact = executed_trades.sum(&:slippage_cost)
      funding_impact = executed_trades.sum(&:funding_cost)

      winners = executed_trades.select(&:winner?)
      losers = executed_trades.select(&:loser?)

      gross_profit = winners.sum(&:executed_pnl)
      gross_loss = losers.sum { |t| t.executed_pnl.abs }

      execution_pf = if gross_profit.zero? && gross_loss.zero?
                       0.0
      elsif gross_loss.zero?
                       10_000.0
      else
                       (gross_profit / gross_loss).round(4)
      end

      ExecutionReport.new(
        executed_trades: executed_trades,
        gross_net_profit: gross_net_profit,
        execution_net_profit: execution_net_profit,
        fee_impact: fee_impact,
        slippage_impact: slippage_impact,
        funding_impact: funding_impact,
        execution_profit_factor: execution_pf
      )
    end
  end
end
