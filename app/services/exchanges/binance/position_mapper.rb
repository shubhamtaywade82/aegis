# frozen_string_literal: true

require "bigdecimal"
require_relative "../../value_objects/position_snapshot"

module Exchanges
  module Binance
    class PositionMapper
      def self.from_binance(pos)
        qty = BigDecimal(pos["positionAmt"] || "0.0")
        side = qty.positive? ? :long : :short

        PositionSnapshot.new(
          symbol: pos["symbol"],
          side: side,
          quantity: qty.abs,
          entry_price: BigDecimal(pos["entryPrice"] || "0.0"),
          mark_price: BigDecimal(pos["markPrice"] || "0.0"),
          unrealized_pnl: BigDecimal(pos["unRealizedProfit"] || "0.0")
        )
      end
    end
  end
end
