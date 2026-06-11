# frozen_string_literal: true

module Exchanges
  class SymbolRegistry
    REGISTRY = {
      binance: {
        "SOLUSDT" => "SOLUSDT",
        "BTCUSDT" => "BTCUSDT",
        "ETHUSDT" => "ETHUSDT"
      },
      coindcx: {
        "SOLUSDT" => "B-SOL_USDT",
        "BTCUSDT" => "B-BTC_USDT",
        "ETHUSDT" => "B-ETH_USDT"
      },
      delta: {
        "SOLUSDT" => "SOLUSDT",
        "BTCUSDT" => "BTCUSDT",
        "ETHUSDT" => "ETHUSDT"
      }
    }.freeze

    def self.resolve(exchange, symbol)
      exch = exchange.to_sym
      REGISTRY.dig(exch, symbol) || symbol
    end

    def self.reverse_resolve(exchange, exchange_symbol)
      exch = exchange.to_sym
      mapping = REGISTRY[exch]
      return exchange_symbol unless mapping

      mapping.key(exchange_symbol) || exchange_symbol
    end
  end
end
