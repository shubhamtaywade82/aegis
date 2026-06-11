# frozen_string_literal: true

require "bigdecimal"

module Monitoring
  class MetricsRegistry
    attr_reader :metrics

    def initialize
      @metrics = {
        # Trading
        signals_generated: 0,
        signals_rejected: 0,
        orders_submitted: 0,
        orders_filled: 0,
        pnl: BigDecimal("0.0"),
        drawdown: BigDecimal("0.0"),
        wins: 0,
        losses: 0,
        gross_profit: BigDecimal("0.0"),
        gross_loss: BigDecimal("0.0"),

        # Risk
        risk_rejections: 0,
        exposure_usage: BigDecimal("0.0"),
        daily_loss_usage: BigDecimal("0.0"),
        cooldown_activations: 0,
        circuit_breakers: 0,

        # Infrastructure
        rest_errors: 0,
        websocket_reconnects: 0,
        websocket_reconnects_outage_seconds: 0,
        clock_drift_ms: 0,
        latency_ms: 0,
        listen_key_renewals: 0,
        reconciliation_failures: 0,

        # Business
        equity: BigDecimal("0.0"),
        account_growth: BigDecimal("0.0"),
        fees_paid: BigDecimal("0.0"),
        funding_paid: BigDecimal("0.0"),
        trade_count: 0,
        total_holding_time: 0
      }
      @history = Hash.new { |h, k| h[k] = [] }
    end

    def record(metric, value)
      val = value.is_a?(Numeric) ? BigDecimal(value.to_s) : value
      @metrics[metric.to_sym] = val
      @history[metric.to_sym] << { timestamp: Time.now, value: val }
    end

    def increment(metric, by = 1)
      @metrics[metric.to_sym] ||= 0
      @metrics[metric.to_sym] += by
      @history[metric.to_sym] << { timestamp: Time.now, value: @metrics[metric.to_sym] }
    end

    def get(metric)
      @metrics[metric.to_sym]
    end

    def history_for(metric)
      @history[metric.to_sym]
    end

    # Derived metrics
    def fill_ratio
      submitted = @metrics[:orders_submitted]
      return 0.0 if submitted.zero?
      (@metrics[:orders_filled].to_f / submitted.to_f).round(4)
    end

    def win_rate
      total = @metrics[:wins] + @metrics[:losses]
      return 0.0 if total.zero?
      (@metrics[:wins].to_f / total.to_f).round(4)
    end

    def profit_factor
      return 0.0 if @metrics[:gross_loss].zero?
      (@metrics[:gross_profit] / @metrics[:gross_loss]).to_f.round(4)
    end

    def average_holding_time
      count = @metrics[:trade_count]
      return 0.0 if count.zero?
      @metrics[:total_holding_time].to_f / count.to_f
    end

    def bind_to_event_bus(event_bus)
      event_bus.subscribe_all do |event|
        process_event(event)
      end
    end

    private

    def process_event(event)
      case event.type
      when "SignalGenerated"
        increment(:signals_generated)
      when "SignalRejected"
        increment(:signals_rejected)
      when "OrderSubmitted"
        increment(:orders_submitted)
      when "OrderFilled"
        increment(:orders_filled)
        pnl = BigDecimal((event.payload[:pnl] || 0.0).to_s)
        if pnl.positive?
          increment(:wins)
          increment(:gross_profit, pnl)
        elsif pnl.negative?
          increment(:losses)
          increment(:gross_loss, pnl.abs)
        end
        increment(:trade_count) if event.payload[:closed]
      when "RiskRejected"
        increment(:risk_rejections)
      when "DailyLossTriggered"
        increment(:daily_loss_usage, event.payload[:usage] || 1.0)
      when "CooldownTriggered"
        increment(:cooldown_activations)
      when "CircuitBreakerTriggered"
        increment(:circuit_breakers)
      when "RestRequestFailed"
        increment(:rest_errors)
      when "WebSocketDisconnected"
        increment(:websocket_reconnects)
        outage = event.payload[:outage_seconds] || 0
        record(:websocket_reconnects_outage_seconds, outage)
      when "ClockDriftDetected"
        record(:clock_drift_ms, event.payload[:drift_ms])
      when "ReconciliationMismatch"
        increment(:reconciliation_failures)
      end
    end
  end
end
