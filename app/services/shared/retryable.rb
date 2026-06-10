# frozen_string_literal: true

# Mixin module that provides configurable retry logic for methods.
# Include in a class to gain the `.retryable` class method.
module Retryable
  # Executes the given block with retry logic.
  #
  # @param max_attempts [Integer] Total tries (1 original + retries)
  # @param base_delay [Float] Initial sleep in seconds between retries
  # @param exponential_backoff [Boolean] If true, delays double each attempt
  # @param retry_on [Array<Exception>] Exception classes to catch and retry
  # @yield [attempt] Block to execute; yields attempt number (1-indexed)
  # @return [Object] Result of the block
  # @raise [Exception] Re-raises the last exception on final failure
  def retryable(max_attempts: 3, base_delay: 0.5, exponential_backoff: true, retry_on: [])
    attempt ||= 0

    begin
      attempt += 1
      yield attempt
    rescue *retry_on => e
      if attempt >= max_attempts
        raise e
      else
        delay = exponential_backoff ? base_delay * (2 ** (attempt - 1)) : base_delay
        sleep(delay)
        retry
      end
    end
  end
end