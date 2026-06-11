# frozen_string_literal: true

require "bigdecimal"

module Execution
  class RiskEngine
    class RiskError < StandardError; end

    CORRELATION_GROUPS = [
      [ "BTC", "ETH" ],
      [ "SOL", "AVAX", "ADA" ],
      [ "DOGE", "SHIB", "PEPE" ]
    ].freeze

    attr_reader :max_positions,
                :max_exposure,
                :max_leverage,
                :daily_loss_limit,
                :max_consecutive_losses,
                :cooldown_period_seconds,
                :max_trades_per_day,
                :max_rest_failures,
                :max_ws_outage_seconds,
                :max_clock_drift_ms,
                :max_correlated_positions

    def initialize(
      max_positions: 3,
      max_exposure: 0.50, # 50% of equity
      max_leverage: 5,
      daily_loss_limit: 0.03, # 3% of equity
      max_consecutive_losses: 3,
      cooldown_period_seconds: 14_400, # 4 hours
      max_trades_per_day: 20,
      max_rest_failures: 5,
      max_ws_outage_seconds: 60,
      max_clock_drift_ms: 500,
      max_correlated_positions: 2,
      max_exchange_errors: nil
    )
      @max_positions = max_positions
      @max_exposure = BigDecimal(max_exposure.to_s)
      @max_leverage = max_leverage
      @daily_loss_limit = BigDecimal(daily_loss_limit.to_s)
      @max_consecutive_losses = max_consecutive_losses
      @cooldown_period_seconds = cooldown_period_seconds
      @max_trades_per_day = max_trades_per_day
      @max_rest_failures = max_exchange_errors || max_rest_failures
      @max_ws_outage_seconds = max_ws_outage_seconds
      @max_clock_drift_ms = max_clock_drift_ms
      @max_correlated_positions = max_correlated_positions
    end

    def validate_order!(order_request:, portfolio:, market_context: {})
      reasons = []
      severity = :none

      # Level 5: Emergency Controls
      if market_context[:kill_switch_active]
        reasons << "Kill switch active. Trading disabled."
        severity = :critical
      end

      if market_context[:panic_flatten_active]
        reasons << "Panic flatten active. Trading disabled."
        severity = :critical
      end

      # Level 4: Infrastructure Risk
      rest_errs = market_context[:rest_failures] || 0
      if rest_errs >= max_rest_failures
        reasons << "Execution circuit breaker active: REST failures (#{rest_errs}) >= limit (#{max_rest_failures})"
        severity = :critical
      end

      if (market_context[:websocket_disconnected_seconds] || 0) > max_ws_outage_seconds
        reasons << "WebSocket outage limit exceeded"
        severity = :critical
      end

      if market_context[:reconciliation_failed]
        reasons << "Reconciliation mismatch detected"
        severity = :critical
      end

      clock_drift = (market_context[:clock_drift_ms] || 0).abs
      if clock_drift > max_clock_drift_ms
        reasons << "Clock drift limit exceeded"
        severity = [ severity, :high ].max_by { |s| severity_priority(s) }
      end

      # Level 3: Daily Risk
      daily_loss = BigDecimal((market_context[:daily_loss] || 0.0).to_s)
      daily_loss_limit_val = if daily_loss_limit <= BigDecimal("1.0")
                               portfolio.equity * daily_loss_limit
      else
                               daily_loss_limit
      end

      if daily_loss >= daily_loss_limit_val
        reasons << "Daily loss limit exceeded: Daily loss (#{daily_loss.to_f}) >= limit (#{daily_loss_limit_val.to_f})"
        severity = :critical
      end

      consecutive_losses = market_context[:consecutive_losses] || 0
      last_loss_time = market_context[:last_loss_time]
      if consecutive_losses >= max_consecutive_losses && last_loss_time
        elapsed = Time.now - last_loss_time
        if elapsed < cooldown_period_seconds
          remaining = (cooldown_period_seconds - elapsed).round
          reasons << "Risk cooldown active: #{consecutive_losses} consecutive losses. Cooldown remaining: #{remaining}s"
          severity = [ severity, :high ].max_by { |s| severity_priority(s) }
        end
      end

      daily_trades = market_context[:daily_trades_count] || 0
      if daily_trades >= max_trades_per_day
        reasons << "Daily trade limit exceeded"
        severity = [ severity, :high ].max_by { |s| severity_priority(s) }
      end

      # Level 1: Position Risk & Level 2: Portfolio Risk
      unless order_request.reduce_only
        # Position count limit
        has_pos = portfolio.positions.key?(order_request.symbol)
        if !has_pos && portfolio.positions.size >= max_positions
          reasons << "Position count limit exceeded: Active positions (#{portfolio.positions.size}) >= limit (#{max_positions})"
          severity = [ severity, :high ].max_by { |s| severity_priority(s) }
        end

        # Leverage limit
        if portfolio.leverage > max_leverage
          reasons << "Leverage limit exceeded"
          severity = :critical
        end

        # Exposure limit
        current_exposure = portfolio.positions.values.sum { |pos| pos.quantity * pos.mark_price }
        order_price = order_request.price || market_context[:mark_price] || BigDecimal("0.0")
        order_exposure = order_request.quantity * order_price
        potential_exposure = current_exposure + order_exposure
        max_exposure_value = if max_exposure <= BigDecimal("1.0")
                               portfolio.equity * max_exposure
        else
                               max_exposure
        end

        if potential_exposure > max_exposure_value
          reasons << "Exposure limit exceeded: Potential exposure (#{potential_exposure.to_f}) > limit (#{max_exposure_value.to_f})"
          severity = [ severity, :high ].max_by { |s| severity_priority(s) }
        end

        # Correlation limit
        group = correlation_group_for(order_request.symbol)
        if group && !has_pos
          active_in_group = portfolio.positions.keys.count { |sym| group.include?(base_asset_of(sym)) }
          if active_in_group >= max_correlated_positions
            reasons << "Correlation limit exceeded"
            severity = [ severity, :medium ].max_by { |s| severity_priority(s) }
          end
        end

        # Risk per trade validation
        entry_price = order_request.price || market_context[:mark_price]
        stop_price = market_context[:stop_price] || order_request.stop_price
        if entry_price && stop_price
          stop_distance = (entry_price - stop_price).abs
          if stop_distance.positive? && portfolio.equity.positive?
            risk_percent = (stop_distance * order_request.quantity) / portfolio.equity
            if risk_percent > BigDecimal("0.005")
              reasons << "Risk per trade limit exceeded"
              severity = [ severity, :high ].max_by { |s| severity_priority(s) }
            end
          end
        end
      end

      approved = reasons.empty?
      final_severity = approved ? :none : severity

      RiskDecision.new(approved: approved, reasons: reasons, severity: final_severity)
    end

    def check!(
      order_request:,
      active_positions:,
      daily_loss:,
      consecutive_losses:,
      last_loss_time: nil,
      exchange_errors: 0,
      cash_balance: 100_000.0
    )
      # Build a temporary portfolio from current position list
      portfolio = Portfolio.new(cash_balance: cash_balance, leverage: max_leverage)
      active_positions.each do |pos|
        portfolio.add_position(pos.symbol, pos.side, pos.quantity, pos.entry_price)
        portfolio.update_mark_price!(pos.symbol, pos.mark_price)
      end

      market_context = {
        daily_loss: daily_loss,
        consecutive_losses: consecutive_losses,
        last_loss_time: last_loss_time,
        rest_failures: exchange_errors
      }

      decision = validate_order!(
        order_request: order_request,
        portfolio: portfolio,
        market_context: market_context
      )

      unless decision.approved?
        raise RiskError, decision.reasons.join(", ")
      end

      true
    end

    private

    def correlation_group_for(symbol)
      base = base_asset_of(symbol)
      CORRELATION_GROUPS.find { |group| group.include?(base) }
    end

    def base_asset_of(symbol)
      symbol.to_s.sub(/USDT\z/, "")
    end

    def severity_priority(severity)
      case severity.to_sym
      when :none then 0
      when :low then 1
      when :medium then 2
      when :high then 3
      when :critical then 4
      else 0
      end
    end
  end
end
