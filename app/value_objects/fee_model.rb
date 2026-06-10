# frozen_string_literal: true

require "bigdecimal"

class FeeModel
  attr_reader :maker_fee,
              :taker_fee,
              :mode

  def initialize(
    mode: :taker,
    maker_fee: 0.0002,
    taker_fee: 0.0005
  )
    @mode = mode.to_sym
    @maker_fee = BigDecimal(maker_fee.to_s)
    @taker_fee = BigDecimal(taker_fee.to_s)

    freeze
  end

  def calculate(entry_notional:, exit_notional:)
    rate = (mode == :maker) ? maker_fee : taker_fee
    ((entry_notional * rate) + (exit_notional * rate)).round(8)
  end
end
