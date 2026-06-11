# frozen_string_literal: true


module Research
  class ExecutionSimulator
    def self.call(
      trades:,
      fee_model:,
      slippage_model:,
      funding_model:,
      latency_model: nil,
      candles: nil
    )
      new(
        trades: trades,
        fee_model: fee_model,
        slippage_model: slippage_model,
        funding_model: funding_model,
        latency_model: latency_model,
        candles: candles
      ).call
    end

    def initialize(
      trades:,
      fee_model:,
      slippage_model:,
      funding_model:,
      latency_model: nil,
      candles: nil
    )
      @trades = trades
      @fee_model = fee_model
      @slippage_model = slippage_model
      @funding_model = funding_model
      @latency_model = latency_model
      @candles = candles
    end

    def call
      executed_trades =
        trades.map do |trade|
          execute_trade(trade)
        end

      build_report(executed_trades)
    end

    private

    attr_reader :trades,
                :fee_model,
                :slippage_model,
                :funding_model,
                :latency_model,
                :candles

    def execute_trade(trade)
      entry_price = trade.entry_price
      exit_price = trade.exit_price

      if latency_model && candles
        entry_idx = find_candle_index(trade.entry_time)
        exit_idx = find_candle_index(trade.exit_time)

        if entry_idx && exit_idx
          delayed_entry_idx = latency_model.delayed_index(entry_idx, candles: candles)
          delayed_exit_idx = latency_model.delayed_index(exit_idx, candles: candles)

          entry_price = candles[delayed_entry_idx].open
          exit_price = candles[delayed_exit_idx].close
        end
      end

      adjusted_entry =
        slippage_model.apply(
          price: entry_price,
          side: entry_side(trade)
        )

      adjusted_exit =
        slippage_model.apply(
          price: exit_price,
          side: exit_side(trade)
        )

      fees =
        fee_model.fee(
          entry_notional:
            adjusted_entry * trade.quantity,

          exit_notional:
            adjusted_exit * trade.quantity
        )

      funding =
        funding_model.cost(
          notional:
            adjusted_entry * trade.quantity
        )

      slippage =
        (
          (adjusted_entry - trade.entry_price).abs +
          (adjusted_exit - trade.exit_price).abs
        ) * trade.quantity

      ExecutedTrade.new(
        trade: trade,
        adjusted_entry_price: adjusted_entry,
        adjusted_exit_price: adjusted_exit,
        fees: fees,
        funding_cost: funding,
        slippage_cost: slippage
      )
    end

    def find_candle_index(time)
      return nil if candles.nil?
      candles.find_index { |c| c.open_time >= time }
    end

    def build_report(executed_trades)
      research_pnls =
        executed_trades.map(&:research_pnl)

      execution_pnls =
        executed_trades.map(&:execution_pnl)

      ExecutionReport.new(
        executed_trades: executed_trades,

        research_net_profit:
          research_pnls.sum,

        execution_net_profit:
          execution_pnls.sum,

        fee_impact:
          executed_trades.sum(&:fees),

        funding_impact:
          executed_trades.sum(&:funding_cost),

        slippage_impact:
          executed_trades.sum(&:slippage_cost),

        research_profit_factor:
          profit_factor(research_pnls),

        execution_profit_factor:
          profit_factor(execution_pnls)
      )
    end

    def profit_factor(pnls)
      gross_profit =
        pnls.select(&:positive?).sum

      gross_loss =
        pnls.select(&:negative?)
            .sum(&:abs)

      return 10_000.0 if gross_loss.zero?

      gross_profit / gross_loss
    end

    def entry_side(trade)
      trade.side == :long ? :buy : :sell
    end

    def exit_side(trade)
      trade.side == :long ? :sell : :buy
    end
  end
end
