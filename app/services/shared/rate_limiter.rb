# frozen_string_literal: true

module Shared
  class RateLimiter
    MAX_WEIGHT = 1_200
    WINDOW = 60

    def initialize(
      max_weight: MAX_WEIGHT,
      window: WINDOW
    )
      @max_weight = max_weight
      @window = window

      reset!
    end

    def consume(weight)
      reset_if_needed!

      if @used_weight + weight > @max_weight
        raise RateLimitError,
              "Binance request weight exceeded"
      end

      @used_weight += weight

      true
    end

    def remaining_weight
      reset_if_needed!

      @max_weight - @used_weight
    end

    def sleep_until_available
      reset_if_needed!

      return if remaining_weight.positive?

      sleep(@window - elapsed)
    end

    private

    def reset!
      @window_started_at = Time.current
      @used_weight = 0
    end

    def reset_if_needed!
      reset! if elapsed >= @window
    end

    def elapsed
      Time.current - @window_started_at
    end
  end
end