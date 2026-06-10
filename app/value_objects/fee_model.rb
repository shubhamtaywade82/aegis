# frozen_string_literal: true

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
    @maker_fee = maker_fee
    @taker_fee = taker_fee

    freeze
  end

  def fee(entry_notional:, exit_notional:)
    rate = mode == :maker ? maker_fee : taker_fee

    (entry_notional * rate) + (exit_notional * rate)
  end
end
