# frozen_string_literal: true

module Shared
  module Retryable
    DEFAULT_ATTEMPTS = 3
    DEFAULT_BASE_DELAY = 0.5

    def with_retry(
      attempts: DEFAULT_ATTEMPTS,
      base_delay: DEFAULT_BASE_DELAY,
      retry_on: [ StandardError ]
    )
      current_attempt = 0

      begin
        current_attempt += 1

        yield
      rescue *retry_on => error
        raise error if current_attempt >= attempts

        sleep(base_delay * (2**(current_attempt - 1)))

        retry
      end
    end
  end
end
