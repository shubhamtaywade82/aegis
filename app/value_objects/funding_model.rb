# frozen_string_literal: true

require "bigdecimal"

class FundingModel
  attr_reader :rate, :interval_hours

  def initialize(rate: 0.0001, interval_hours: 8)
    @rate = BigDecimal(rate.to_s)
    @interval_hours = interval_hours
    freeze
  end

  def cost(notional:, duration_seconds:)
    duration_hours = BigDecimal(duration_seconds.to_s) / 3600.0

    intervals = if interval_hours.zero?
                  duration_hours
    else
                  (duration_hours / interval_hours).floor
    end

    (notional * rate * intervals).round(8)
  end
end
