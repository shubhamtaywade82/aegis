# frozen_string_literal: true

require "bigdecimal"

module Strategy
  class SupertrendStrategy
    attr_reader :symbols,
                :paper_engine,
                :execution_engine,
                :signal_monitor,
                :position_tracker,
                :order_generator

    def initialize(
      symbols:,
      paper_engine:,
      execution_engine:,
      signal_monitor:,
      position_tracker:,
      order_generator:
    )
      @symbols = symbols
      @paper_engine = paper_engine
      @execution_engine = execution_engine
      @signal_monitor = signal_monitor
      @position_tracker = position_tracker
      @order_generator = order_generator
    end

    # Evaluates a single symbol: fetches price, checks flip, generates/executes orders, syncs position
    def evaluate_symbol(symbol)
      price = fetch_latest_price(symbol)
      return if price.nil?

      paper_engine.set_price(symbol, price)

      result = signal_monitor.update_and_check(symbol)
      return unless result[:flipped]

      current_position = position_tracker.current_position(symbol)

      orders = order_generator.generate_orders(
        symbol: symbol,
        current_price: price,
        new_direction: result[:to],
        current_position: current_position
      )

      return if orders.empty?

      orders.each do |order|
        begin
          execution_engine.execute(order)
          sync_position(symbol)
        rescue Execution::RiskEngine::RiskError => e
          Rails.logger.warn "[SupertrendStrategy] Risk check failed for #{symbol}: #{e.message}"
          break
        rescue StandardError => e
          Rails.logger.error "[SupertrendStrategy] Order execution failed for #{symbol}: #{e.message}"
          break
        end
      end
    end

    # Evaluates all configured symbols
    def execute
      symbols.each { |symbol| evaluate_symbol(symbol) }
    end

    private

    # Reads Redis ticker JSON and extracts "c" field as BigDecimal
    def fetch_latest_price(symbol)
      data = MarketDataFeed.redis.get("trading:ticks:#{symbol}")
      return nil unless data

      parsed = JSON.parse(data)
      price_str = parsed["c"]
      return nil if price_str.nil?

      BigDecimal(price_str.to_s)
    rescue JSON::ParserError, StandardError
      nil
    end

    # Syncs position state from PaperEngine back to PositionTracker
    def sync_position(symbol)
      pos = paper_engine.positions.find { |p| p.symbol == symbol }

      if pos
        position_tracker.set_position(
          symbol,
          side: pos.side,
          quantity: pos.quantity,
          entry_price: pos.entry_price
        )
      else
        position_tracker.clear_position(symbol)
      end
    end
  end
end