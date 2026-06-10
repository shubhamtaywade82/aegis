# frozen_string_literal: true

class ParameterSet
  attr_reader :length,
              :multiplier,
              :stable_score,
              :profit_factor,
              :trade_count

  def initialize(
    length:,
    multiplier:,
    stable_score:,
    profit_factor:,
    trade_count:
  )
    @length = length
    @multiplier = multiplier
    @stable_score = stable_score
    @profit_factor = profit_factor
    @trade_count = trade_count
    freeze
  end

  def valid?
    length.positive? &&
      multiplier.positive? &&
      trade_count >= 20
  end

  def identifier
    "#{length}-#{multiplier}"
  end
end
