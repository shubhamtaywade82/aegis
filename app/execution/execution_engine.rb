# frozen_string_literal: true

require "bigdecimal"
require_relative "risk_engine"
require_relative "../value_objects/order_request"
require_relative "../value_objects/order_response"

module Execution
  class ExecutionEngine
    attr_reader :adapter,
                :risk_engine,
                :daily_loss,
                :consecutive_losses,
                :last_loss_time,
                :exchange_errors

    def initialize(
      adapter:,
      risk_engine:
    )
      @adapter = adapter
      @risk_engine = risk_engine
      @daily_loss = BigDecimal("0.0")
      @consecutive_losses = 0
      @last_loss_time = nil
      @exchange_errors = 0
    end

    def execute(order_request)
      active_positions = adapter.positions

      risk_engine.check!(
        order_request: order_request,
        active_positions: active_positions,
        daily_loss: daily_loss,
        consecutive_losses: consecutive_losses,
        last_loss_time: last_loss_time,
        exchange_errors: exchange_errors
      )

      begin
        response = adapter.place_order(order_request)

        @exchange_errors = 0

        response
      rescue => e
        @exchange_errors += 1
        raise e
      end
    end

    def record_pnl(amount)
      pnl = BigDecimal(amount.to_s)
      if pnl.negative?
        @daily_loss += pnl.abs
        @consecutive_losses += 1
        @last_loss_time = Time.now
      else
        @consecutive_losses = 0
      end
    end

    def reset_daily_stats!
      @daily_loss = BigDecimal("0.0")
    end
  end
end
