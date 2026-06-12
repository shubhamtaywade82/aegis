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
      Rails.logger.info "[SupertrendStrategy] ===== Evaluating #{symbol} ====="

      price = fetch_latest_price(symbol)
      if price.nil?
        Rails.logger.warn "[SupertrendStrategy] #{symbol}: No price in Redis (key trading:ticks:#{symbol}), skipping"
        return
      end
      Rails.logger.info "[SupertrendStrategy] #{symbol}: Price = #{price.to_f}"

      paper_engine.set_price(symbol, price)

      result = signal_monitor.update_and_check(symbol)
      Rails.logger.info "[SupertrendStrategy] #{symbol}: Direction previous=#{result[:from].inspect} current=#{result[:to].inspect} flipped=#{result[:flipped]}"

      return unless result[:flipped]
      Rails.logger.info "[SupertrendStrategy] #{symbol}: FLIP detected! #{result[:from]} -> #{result[:to]}"

      current_position = position_tracker.current_position(symbol)
      Rails.logger.info "[SupertrendStrategy] #{symbol}: Tracked position = #{current_position.inspect}"

      orders = order_generator.generate_orders(
        symbol: symbol,
        current_price: price,
        new_direction: result[:to],
        current_position: current_position
      )
      Rails.logger.info "[SupertrendStrategy] #{symbol}: Generated #{orders.size} orders"
      orders.each_with_index do |o, i|
        Rails.logger.info "[SupertrendStrategy] #{symbol}: Order[#{i}] side=#{o.side} qty=#{o.quantity.to_f} reduce_only=#{o.reduce_only}"
      end

      return if orders.empty?
      Rails.logger.info "[SupertrendStrategy] #{symbol}: Executing #{orders.size} orders..."

      orders.each do |order|
        begin
          response = execution_engine.execute(order)
          Rails.logger.info "[SupertrendStrategy] #{symbol}: Order EXECUTED side=#{order.side} qty=#{order.quantity.to_f} reduce_only=#{order.reduce_only} status=#{response.status}"
          sync_position(symbol)
          synced = position_tracker.current_position(symbol)
          Rails.logger.info "[SupertrendStrategy] #{symbol}: Position synced -> #{synced.inspect}"
        rescue Execution::RiskEngine::RiskError => e
          Rails.logger.warn "[SupertrendStrategy] #{symbol}: Risk check failed -> #{e.message}"
          break
        rescue StandardError => e
          Rails.logger.error "[SupertrendStrategy] #{symbol}: Order execution error -> #{e.class}: #{e.message}"
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