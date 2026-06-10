# frozen_string_literal: true

require 'thread'

# Thread-safe rate limiter for API request weights.
# Resets the counter every 60 seconds using monotonic clock.
class RateLimiter
  WINDOW_SECONDS = 60

  # @param weight_per_minute [Integer] Maximum weight allowed per minute
  def initialize(weight_per_minute: 1200)
    @weight_per_minute = weight_per_minute
    @mutex = Mutex.new
    @consumed = 0
    @window_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  # Consume weight, blocking if necessary until capacity is available.
  #
  # @param weight [Integer] Amount of weight to consume
  # @return [Integer] Remaining weight after consumption
  def consume(weight)
    @mutex.synchronize do
      wait_for_capacity(weight)
      @consumed += weight
      @weight_per_minute - @consumed
    end
  end

  # @return [Integer] Current remaining capacity
  def remaining_weight
    @mutex.synchronize do
      ensure_window_reset
      [@weight_per_minute - @consumed, 0].max
    end
  end

  # @return [Float] Seconds until the next window reset
  def sleep_until_next_available
    @mutex.synchronize do
      ensure_window_reset
      0.0
    end
  end

  private

  def ensure_window_reset
    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed = now - @window_start
    if elapsed >= WINDOW_SECONDS
      @consumed = 0
      @window_start = now
    end
  end

  def wait_for_capacity(weight)
    while true
      ensure_window_reset
      if @consumed + weight <= @weight_per_minute
        return
      end
      # Calculate sleep duration until next window
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed = now - @window_start
      sleep_duration = WINDOW_SECONDS - elapsed
      sleep(sleep_duration) if sleep_duration > 0
    end
  end
end