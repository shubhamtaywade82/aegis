# frozen_string_literal: true

require "bigdecimal"

module Monitoring
  class AlertEngine
    attr_reader :alerts

    def initialize(notifier: nil, execution_engine: nil)
      @notifier = notifier
      @execution_engine = execution_engine
      @alerts = []
    end

    def check_metrics!(metrics_registry)
      # Check WebSocket Outage
      ws_outage = metrics_registry.get(:websocket_reconnects_outage_seconds) || 0
      if ws_outage > 30
        trigger_alert(
          severity: :critical,
          message: "WebSocket outage detected: Disconnected for #{ws_outage} seconds.",
          action: :pause_trading
        )
      end

      # Check Daily Loss
      daily_loss_usage = BigDecimal((metrics_registry.get(:daily_loss_usage) || 0.0).to_s)
      if daily_loss_usage >= BigDecimal("1.0")
        trigger_alert(
          severity: :emergency,
          message: "Daily loss limit breached: 100% usage reached.",
          action: :disable_trading
        )
      elsif daily_loss_usage > BigDecimal("0.80")
        remaining = (BigDecimal("1.0") - daily_loss_usage) * 100
        trigger_alert(
          severity: :warning,
          message: "Daily loss usage warning: #{(daily_loss_usage * 100).to_f.round(1)}% usage. Remaining capacity: #{remaining.to_f.round(1)}%"
        )
      end

      # Check Circuit Breakers
      breakers = metrics_registry.get(:circuit_breakers) || 0
      if breakers.positive?
        trigger_alert(
          severity: :emergency,
          message: "Circuit Breaker Triggered. Trading Disabled.",
          action: :disable_trading
        )
      end

      # Check Reconciliation Failure
      recon_failures = metrics_registry.get(:reconciliation_failures) || 0
      if recon_failures.positive?
        trigger_alert(
          severity: :critical,
          message: "Reconciliation mismatch detected. Manual intervention required.",
          action: :pause_trading
        )
      end
    end

    def trigger_alert(severity:, message:, action: nil)
      alert = {
        severity: severity.to_sym,
        message: message,
        action: action,
        timestamp: Time.now
      }.freeze
      @alerts << alert

      @notifier&.notify(alert)

      alert
    end
  end
end
