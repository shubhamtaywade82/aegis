# frozen_string_literal: true

require "securerandom"
require "bigdecimal"

class OrderRequest
  attr_reader :symbol,
              :side,
              :quantity,
              :order_type,
              :price,
              :stop_price,
              :reduce_only,
              :client_order_id

  def initialize(
    symbol:,
    side:,
    quantity:,
    order_type:,
    price: nil,
    stop_price: nil,
    reduce_only: false,
    client_order_id: nil
  )
    @symbol = symbol
    @side = side.to_sym
    @quantity = BigDecimal(quantity.to_s)
    @order_type = order_type.to_sym
    @price = price ? BigDecimal(price.to_s) : nil
    @stop_price = stop_price ? BigDecimal(stop_price.to_s) : nil
    @reduce_only = reduce_only
    @client_order_id = client_order_id || SecureRandom.hex(10)

    validate!
    freeze
  end

  private

  def validate!
    raise ArgumentError, "symbol cannot be blank" if symbol.nil? || symbol.strip.empty?
    raise ArgumentError, "invalid side: #{side}" unless %i[buy sell].include?(side)
    raise ArgumentError, "quantity must be positive" unless quantity.positive?
    raise ArgumentError, "invalid order_type: #{order_type}" unless %i[market limit stop_market take_profit_market].include?(order_type)
    raise ArgumentError, "price is required for limit orders" if order_type == :limit && price.nil?
    raise ArgumentError, "stop_price is required for stop/take_profit orders" if %i[stop_market take_profit_market].include?(order_type) && stop_price.nil?
  end
end
