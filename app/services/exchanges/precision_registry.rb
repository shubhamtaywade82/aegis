# frozen_string_literal: true

require "bigdecimal"

module Exchanges
  class PrecisionRegistry
    REGISTRY = {
      binance: {
        "SOLUSDT" => { tick_size: BigDecimal("0.01"), step_size: BigDecimal("0.001"), min_notional: BigDecimal("5.0"), price_precision: 2, quantity_precision: 3 },
        "BTCUSDT" => { tick_size: BigDecimal("0.1"), step_size: BigDecimal("0.00001"), min_notional: BigDecimal("5.0"), price_precision: 1, quantity_precision: 5 },
        "ETHUSDT" => { tick_size: BigDecimal("0.01"), step_size: BigDecimal("0.0001"), min_notional: BigDecimal("5.0"), price_precision: 2, quantity_precision: 4 }
      },
      coindcx: {
        "SOLUSDT" => { tick_size: BigDecimal("0.01"), step_size: BigDecimal("0.01"), min_notional: BigDecimal("1.0"), price_precision: 2, quantity_precision: 2 },
        "BTCUSDT" => { tick_size: BigDecimal("1.0"), step_size: BigDecimal("0.0001"), min_notional: BigDecimal("1.0"), price_precision: 0, quantity_precision: 4 },
        "ETHUSDT" => { tick_size: BigDecimal("0.1"), step_size: BigDecimal("0.001"), min_notional: BigDecimal("1.0"), price_precision: 1, quantity_precision: 3 }
      },
      delta: {
        "SOLUSDT" => { tick_size: BigDecimal("0.01"), step_size: BigDecimal("0.01"), min_notional: BigDecimal("1.0"), price_precision: 2, quantity_precision: 2 },
        "BTCUSDT" => { tick_size: BigDecimal("0.5"), step_size: BigDecimal("0.001"), min_notional: BigDecimal("1.0"), price_precision: 1, quantity_precision: 3 },
        "ETHUSDT" => { tick_size: BigDecimal("0.05"), step_size: BigDecimal("0.01"), min_notional: BigDecimal("1.0"), price_precision: 2, quantity_precision: 2 }
      }
    }.freeze

    def self.for(exchange, symbol)
      exch = exchange.to_sym
      REGISTRY.dig(exch, symbol) || {
        tick_size: BigDecimal("0.01"),
        step_size: BigDecimal("0.01"),
        min_notional: BigDecimal("1.0"),
        price_precision: 2,
        quantity_precision: 2
      }
    end
  end
end
