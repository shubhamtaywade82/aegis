# frozen_string_literal: true

module Monitoring
  class DashboardService
    def initialize(metrics_registry:, portfolio:, system_status: {})
      @metrics_registry = metrics_registry
      @portfolio = portfolio
      @system_status = system_status
    end

    def render
      {
        strategy: {
          signals_today: @metrics_registry.get(:signals_generated) || 0,
          trades_today: @metrics_registry.get(:trade_count) || 0,
          win_rate: @metrics_registry.win_rate,
          profit_factor: @metrics_registry.profit_factor
        },
        portfolio: {
          equity: @portfolio.equity.to_f.round(2),
          pnl: @portfolio.realized_pnl.to_f.round(2),
          exposure: @portfolio.positions.values.sum { |pos| pos.quantity * pos.mark_price }.to_f.round(2),
          open_positions: @portfolio.positions.keys
        },
        infrastructure: {
          rest_status: @system_status[:rest_connected] ? "ONLINE" : "OFFLINE",
          ws_status: @system_status[:ws_connected] ? "CONNECTED" : "DISCONNECTED",
          latency_ms: @metrics_registry.get(:latency_ms) || 0,
          reconnect_count: @metrics_registry.get(:websocket_reconnects) || 0
        },
        risk: {
          daily_loss_usage: @metrics_registry.get(:daily_loss_usage).to_f.round(4),
          cooldown_status: @system_status[:in_cooldown] ? "ACTIVE" : "INACTIVE",
          circuit_breakers: @metrics_registry.get(:circuit_breakers) || 0,
          kill_switch: @system_status[:kill_switch_active] ? "ACTIVATED" : "DEACTIVATED"
        }
      }
    end
  end
end
