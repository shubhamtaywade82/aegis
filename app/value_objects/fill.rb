# frozen_string_literal: true

require "bigdecimal"

class Fill
  attr_reader :order_id,
              :symbol,
              :side,
              :quantity,
              :price,
              :fee,
              :timestamp

  def initialize(
    order_id:,
    symbol:,
    side:,
    quantity:,
    price:,
    fee:,
    timestamp: Time.now
  )
    @order_id = order_id
    @symbol = symbol
    @side = side.to_sym
    @quantity = BigDecimal(quantity.to_s)
    @price = BigDecimal(price.to_s)
    @fee = BigDecimal(fee.to_s)
    @timestamp = timestamp

    freeze
  end
end
