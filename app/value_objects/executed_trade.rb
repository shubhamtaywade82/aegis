# frozen_string_literal: true

require "bigdecimal"

class ExecutedTrade
  attr_reader :original_trade,
              :executed_entry_price,
              :executed_exit_price,
              :slippage_cost,
              :fee_cost,
              :funding_cost,
              :executed_pnl

  def initialize(
    original_trade:,
    executed_entry_price:,
    executed_exit_price:,
    slippage_cost:,
    fee_cost:,
    funding_cost:,
    executed_pnl:
  )
    @original_trade = original_trade
    @executed_entry_price = BigDecimal(executed_entry_price.to_s)
    @executed_exit_price = BigDecimal(executed_exit_price.to_s)
    @slippage_cost = BigDecimal(slippage_cost.to_s)
    @fee_cost = BigDecimal(fee_cost.to_s)
    @funding_cost = BigDecimal(funding_cost.to_s)
    @executed_pnl = BigDecimal(executed_pnl.to_s)

    freeze
  end

  delegate :symbol,
           :side,
           :entry_time,
           :exit_time,
           :quantity,
           :reason,
           to: :original_trade

  def winner?
    executed_pnl.positive?
  end

  def loser?
    executed_pnl.negative?
  end
end
