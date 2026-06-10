# frozen_string_literal: true

class LatencyModel
  attr_reader :milliseconds

  def initialize(milliseconds:)
    @milliseconds = milliseconds
  end

  def delayed_index(index, candles:)
    bars_delayed = (milliseconds / 1000.0).ceil

    [ index + bars_delayed, candles.size - 1 ].min
  end
end
