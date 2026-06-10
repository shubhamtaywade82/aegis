# frozen_string_literal: true

require "bigdecimal"

module Execution
  class RiskEngine
    class RiskError < StandardError; end

    attr_reader :max_positions,
                :max_exposure,
                :max_leverage,
                :daily_loss_limit,
                :max_consecutive_losses,
                :cooldown_period_seconds,
                :max_exchange_errors

    def initialize(
      max_positions: 5,
      max_exposure: 50_000.0,
      max_leverage: 10,
      daily_loss_limit: 1000.0,
      max_consecutive_losses: 3,
      cooldown_period_seconds: 14_400, # 4 hours
      max_exchange_errors: 5
    )
      @max_positions = max_positions
      @max_exposure = BigDecimal(max_exposure.to_s)
      @max_leverage = max_leverage
      @daily_loss_limit = BigDecimal(daily_loss_limit.to_s)
      @max_consecutive_losses = max_consecutive_losses
      @cooldown_period_seconds = cooldown_period_seconds
      @max_exchange_errors = max_exchange_errors
    end

    def check!(
      order_request:,
      active_positions:,
      daily_loss:,
      consecutive_losses:,
      last_loss_time: nil,
      exchange_errors: 0
    )
      if exchange_errors >= max_exchange_errors
        raise RiskError, "Execution circuit breaker active: Exchange errors (#{exchange_errors}) >= limit (#{max_exchange_errors})"
      end

      if daily_loss >= daily_loss_limit
        raise RiskError, "Daily loss limit exceeded: Daily loss (#{daily_loss.to_f}) >= limit (#{daily_loss_limit.to_f})"
      end

      if consecutive_losses >= max_consecutive_losses
        if last_loss_time && (Time.now - last_loss_time) < cooldown_period_seconds
          remaining = (cooldown_period_seconds - (Time.now - last_loss_time)).round
          raise RiskError, "Risk cooldown active: #{consecutive_losses} consecutive losses. Cooldown remaining: #{remaining}s"
        end
      end

      unless order_request.reduce_only
        has_pos = active_positions.any? { |pos| pos.symbol == order_request.symbol }
        if !has_pos && active_positions.size >= max_positions
          raise RiskError, "Position count limit exceeded: Active positions (#{active_positions.size}) >= limit (#{max_positions})"
        end
      end

      new_exposure = active_positions.sum { |pos| pos.quantity * pos.mark_price }
      unless order_request.reduce_only
        order_price = order_request.price || order_request.stop_price || BigDecimal("0.0")
        new_exposure += order_request.quantity * order_price
      end

      if new_exposure > max_exposure
        raise RiskError, "Exposure limit exceeded: Potential exposure (#{new_exposure.to_f}) > limit (#{max_exposure.to_f})"
      end

      true
    end
  end
end
