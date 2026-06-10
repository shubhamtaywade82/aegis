# frozen_string_literal: true

require "bigdecimal"

class SlippageModel
  attr_reader :mode, :bps, :atr_multiplier

  def initialize(mode: :fixed, bps: 0.0, atr_multiplier: 0.0)
    @mode = mode.to_sym
    @bps = BigDecimal(bps.to_s)
    @atr_multiplier = BigDecimal(atr_multiplier.to_s)
    freeze
  end

  def apply(price:, side:, transaction_type:, atr: nil)
    price = BigDecimal(price.to_s)

    adjustment =
      case mode
      when :fixed
        price * (bps / 10_000.0)
      when :atr
        if atr.nil?
          raise ArgumentError, "ATR is required for ATR-based slippage"
        end
        BigDecimal(atr.to_s) * atr_multiplier
      else
        BigDecimal("0.0")
      end

    is_buy = (side.to_sym == :long && transaction_type.to_sym == :entry) ||
             (side.to_sym == :short && transaction_type.to_sym == :exit)

    if is_buy
      price + adjustment
    else
      price - adjustment
    end
  end
end
