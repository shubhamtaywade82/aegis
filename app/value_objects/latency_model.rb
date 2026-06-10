# frozen_string_literal: true

require "bigdecimal"

class LatencyModel
  attr_reader :mode, :delay_seconds

  def initialize(mode: :constant, delay_seconds: 0.0)
    @mode = mode.to_sym
    @delay_seconds = BigDecimal(delay_seconds.to_s)
    freeze
  end

  def delayed_time(time)
    time + delay_seconds
  end

  def delayed_index(index, interval_seconds:, max_index:)
    return index if delay_seconds.zero?

    bars_delayed = (delay_seconds / BigDecimal(interval_seconds.to_s)).ceil
    [ index + bars_delayed, max_index ].min
  end
end
