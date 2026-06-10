# frozen_string_literal: true

require_relative 'application_error'

# Base class for all upstream service failures (Binance, Telegram, Redis, etc.).
class ExternalServiceError < ApplicationError
  def initialize(message = nil, code: :external_service_error, details: {}, caused_by: nil)
    super(message, code: code, details: details, caused_by: caused_by)
  end
end
