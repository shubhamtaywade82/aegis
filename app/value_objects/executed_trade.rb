# frozen_string_literal: true

class ExecutedTrade
  attr_reader :trade,
              :adjusted_entry_price,
              :adjusted_exit_price,
              :fees,
              :funding_cost,
              :slippage_cost,
              :research_pnl,
              :execution_pnl

  def initialize(
    trade:,
    adjusted_entry_price:,
    adjusted_exit_price:,
    fees:,
    funding_cost:,
    slippage_cost:
  )
    @trade = trade

    @adjusted_entry_price = adjusted_entry_price
    @adjusted_exit_price = adjusted_exit_price

    @fees = fees
    @funding_cost = funding_cost
    @slippage_cost = slippage_cost

    @research_pnl = trade.pnl
    @execution_pnl = calculate_execution_pnl

    freeze
  end

  private

  def calculate_execution_pnl
    gross =
      case trade.side
      when :long
        (adjusted_exit_price - adjusted_entry_price) *
          trade.quantity
      when :short
        (adjusted_entry_price - adjusted_exit_price) *
          trade.quantity
      end

    (
      gross -
      fees -
      funding_cost
    ).round(8)
  end
end
