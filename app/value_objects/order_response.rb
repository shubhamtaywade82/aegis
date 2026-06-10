# frozen_string_literal: true

require "bigdecimal"

class OrderResponse
  attr_reader :exchange_order_id,
              :client_order_id,
              :status,
              :filled_quantity,
              :average_price,
              :raw_response

  def initialize(
    exchange_order_id:,
    client_order_id:,
    status:,
    filled_quantity:,
    average_price:,
    raw_response: {}
  )
    @exchange_order_id = exchange_order_id
    @client_order_id = client_order_id
    @status = status.to_sym
    @filled_quantity = BigDecimal(filled_quantity.to_s)
    @average_price = BigDecimal(average_price.to_s)
    @raw_response = raw_response

    freeze
  end

  def filled?
    status == :filled
  end

  def rejected?
    status == :rejected
  end
end
