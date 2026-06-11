# frozen_string_literal: true

module Exchanges
  class ExchangeRouter
    attr_reader :adapters

    def initialize(adapters = {})
      @adapters = {}
      adapters.each { |k, v| register_adapter(k, v) }
    end

    def register_adapter(name, adapter)
      @adapters[name.to_sym] = adapter
    end

    def place_order(exchange:, order_request:)
      adapter = resolve_adapter(exchange)
      validate_capabilities!(adapter, :place_order)
      adapter.place_order(order_request)
    end

    def cancel_order(exchange:, symbol:, order_id:)
      adapter = resolve_adapter(exchange)
      validate_capabilities!(adapter, :cancel_order)
      adapter.cancel_order(symbol: symbol, order_id: order_id)
    end

    def positions(exchange:)
      adapter = resolve_adapter(exchange)
      validate_capabilities!(adapter, :positions)
      adapter.positions
    end

    def account(exchange:)
      adapter = resolve_adapter(exchange)
      validate_capabilities!(adapter, :account)
      adapter.account
    end

    def latest_price(exchange:, symbol:)
      adapter = resolve_adapter(exchange)
      validate_capabilities!(adapter, :latest_price)
      adapter.latest_price(symbol)
    end

    private

    def resolve_adapter(exchange)
      @adapters[exchange.to_sym] || raise(ArgumentError, "No adapter registered for exchange: #{exchange}")
    end

    def validate_capabilities!(adapter, operation)
      return unless adapter.respond_to?(:capabilities)
      caps = adapter.capabilities
      return if caps.nil?

      if operation == :place_order && !caps[:limit_orders] && !caps[:market_orders]
        raise ArgumentError, "Adapter #{adapter.class.name} does not support placing orders"
      end
    end
  end
end
