# frozen_string_literal: true

class SlippageModel
  attr_reader :bps

  def initialize(bps:)
    @bps = bps
  end

  def apply(price:, side:)
    adjustment = price * (bps / 10_000.0)

    case side.to_sym
    when :buy, :long
      price + adjustment
    when :sell, :short
      price - adjustment
    else
      price
    end
  end
end
