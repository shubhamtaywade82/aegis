# frozen_string_literal: true


module Execution
  class PaperBroker
    attr_reader :portfolio,
                :event_store,
                :slippage_model,
                :risk_engine,
                :open_orders

    def initialize(
      portfolio:,
      event_store:,
      slippage_model:,
      risk_engine: nil
    )
      @portfolio = portfolio
      @event_store = event_store
      @slippage_model = slippage_model
      @risk_engine = risk_engine
      @open_orders = []
    end

    def submit_order(order_request)
      event_store.emit(:OrderSubmitted, order_request: order_request)

      if risk_engine
        begin
          risk_engine.check!(
            order_request: order_request,
            active_positions: portfolio.positions.values,
            daily_loss: portfolio.daily_pnl.negative? ? portfolio.daily_pnl.abs : BigDecimal("0.0"),
            consecutive_losses: 0,
            exchange_errors: 0
          )
        rescue Execution::RiskEngine::RiskError => e
          event_store.emit(:RiskTriggered, reason: e.message)
          event_store.emit(:OrderRejected, order_request: order_request, reason: e.message)
          raise e
        end
      end

      event_store.emit(:OrderAccepted, order_request: order_request)
      open_orders << order_request

      OrderResponse.new(
        exchange_order_id: order_request.client_order_id,
        client_order_id: order_request.client_order_id,
        status: :new,
        filled_quantity: BigDecimal("0.0"),
        average_price: BigDecimal("0.0"),
        raw_response: { accepted: true }
      )
    end

    def cancel_order(order_id)
      order = open_orders.find { |o| o.client_order_id == order_id }
      if order
        open_orders.delete(order)
        event_store.emit(:OrderCanceled, order_id: order_id)
        true
      else
        false
      end
    end

    def process_candle(candle, latest_price, symbol)
      portfolio.update_mark_price!(symbol, latest_price)

      fills = MatchingEngine.match(
        open_orders: open_orders,
        candle: candle,
        latest_price: latest_price,
        slippage_model: slippage_model,
        symbol: symbol
      )

      fills.each do |fill|
        process_fill(fill)
      end
    end

    private

    def process_fill(fill)
      order = open_orders.find { |o| o.client_order_id == fill.order_id }
      open_orders.delete(order) if order

      event_store.emit(:OrderFilled, fill: fill)

      portfolio.cash_balance -= fill.fee

      side = fill.side == :buy ? :long : :short
      existing = portfolio.positions[fill.symbol]

      if existing
        if existing.side == side
          event_store.emit(:PositionIncreased, symbol: fill.symbol, quantity: fill.quantity)
        else
          if fill.quantity >= existing.quantity
            event_store.emit(:PositionClosed, symbol: fill.symbol)
            if fill.quantity > existing.quantity
              event_store.emit(:PositionOpened, symbol: fill.symbol, side: side, quantity: fill.quantity - existing.quantity)
            end
          else
            event_store.emit(:PositionReduced, symbol: fill.symbol, quantity: fill.quantity)
          end
        end
      else
        event_store.emit(:PositionOpened, symbol: fill.symbol, side: side, quantity: fill.quantity)
      end

      portfolio.add_position(fill.symbol, side, fill.quantity, fill.price)
    end
  end
end
