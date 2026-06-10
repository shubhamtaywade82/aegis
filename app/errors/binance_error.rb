# frozen_string_literal: true

require_relative 'external_service_error'

# Raised when the Binance API returns an error response, network failure,
# or unexpected payload structure.
class BinanceError < ExternalServiceError
  def initialize(message = nil, code: :binance_error, details: {}, caused_by: nil)
    super(message, code: code, details: details, caused_by: caused_by)
  end
end
