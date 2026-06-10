# frozen_string_literal: true

require_relative 'external_service_error'

# Raised when an upstream service signals that a rate limit has been exceeded.
# Includes `retry_after` (seconds) when available from the service response.
class RateLimitError < BinanceError
  attr_reader :retry_after

  def initialize(
    message = nil,
    code: :rate_limit_error,
    details: {},
    caused_by: nil,
    retry_after: nil
  )
    @retry_after = retry_after
    super(message, code: code, details: details, caused_by: caused_by)
  end

  def to_h
    super.merge(retry_after: retry_after)
  end
end
