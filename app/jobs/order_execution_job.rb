# frozen_string_literal: true

class OrderExecutionJob < ApplicationJob
  queue_as :critical

  def perform(client_order_id, execution_price_str)
    price = BigDecimal(execution_price_str)
    
    order = Order.find_by!(client_order_id: client_order_id)
    return if order.status == "FILLED"

    WalletLedgerService.settle_trade!(
      user_id: order.user_id,
      symbol: order.symbol,
      side: order.side,
      execution_price: price,
      qty: order.quantity,
      client_order_id: client_order_id,
      leverage: order.leverage
    )
  end
end
