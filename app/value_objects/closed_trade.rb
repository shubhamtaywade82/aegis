# frozen_string_literal: true

require "bigdecimal"

class ClosedTrade
  attr_reader :entry_price,
              :exit_price,
              :quantity,
              :fees,
              :realized_pnl,
              :holding_period,
              :exit_reason

  def initialize(
    entry_price:,
    exit_price:,
    quantity:,
    fees:,
    realized_pnl:,
    holding_period:,
    exit_reason:
  )
    @entry_price = BigDecimal(entry_price.to_s)
    @exit_price = BigDecimal(exit_price.to_s)
    @quantity = BigDecimal(quantity.to_s)
    @fees = BigDecimal(fees.to_s)
    @realized_pnl = BigDecimal(realized_pnl.to_s)
    @holding_period = holding_period
    @exit_reason = exit_reason

    freeze
  end
end
