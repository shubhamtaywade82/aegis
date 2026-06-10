# frozen_string_literal: true

class StableRegion
  attr_reader :length,
              :multiplier,
              :score,
              :average_profit_factor,
              :standard_deviation

  def initialize(
    length:,
    multiplier:,
    score:,
    average_profit_factor:,
    standard_deviation:
  )
    @length = length
    @multiplier = multiplier
    @score = score
    @average_profit_factor = average_profit_factor
    @standard_deviation = standard_deviation

    freeze
  end

  def summary
    {
      length: length,
      multiplier: multiplier,
      score: score,
      average_profit_factor: average_profit_factor,
      standard_deviation: standard_deviation
    }
  end
end
