# frozen_string_literal: true

require "bigdecimal"

class PositionSnapshot
  attr_reader :symbol,
              :side,
              :quantity,
              :entry_price,
              :mark_price,
              :unrealized_pnl

  def initialize(
    symbol:,
    side:,
    quantity:,
    entry_price:,
    mark_price:,
    unrealized_pnl:
  )
    @symbol = symbol
    @side = side.to_sym
    @quantity = BigDecimal(quantity.to_s)
    @entry_price = BigDecimal(entry_price.to_s)
    @mark_price = BigDecimal(mark_price.to_s)
    @unrealized_pnl = BigDecimal(unrealized_pnl.to_s)

    freeze
  end

  def flat?
    side == :flat || quantity.zero?
  end
end
