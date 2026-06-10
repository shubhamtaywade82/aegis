# frozen_string_literal: true

# Base error class for the trading platform.
# All domain errors inherit from ApplicationError to allow broad rescue clauses
# and consistent structured error reporting.
class ApplicationError < StandardError
  attr_reader :code, :details, :caused_by

  # @param message [String, nil] human-readable description; defaults to derived class name
  # @param code [Symbol, String, nil] machine-readable error code
  # @param details [Hash] arbitrary context (field names, values, etc.)
  # @param caused_by [Exception, nil] underlying exception that triggered this error
  def initialize(message = nil, code: nil, details: {}, caused_by: nil)
    @code      = code
    @details   = details
    @caused_by = caused_by
    super(message || default_message)
    freeze
  end

  # Derives a default message from the class name:
  #   "RateLimitError" → "Rate limit error"
  def default_message
    self.class.name
        .split('::').last
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('_', ' ')
        .capitalize
  end

  # Returns a structured hash useful for logging, JSON APIs, and telemetry.
  # Recursively includes `caused_by.to_h` if the wrapped error is also an ApplicationError.
  def to_h
    hash = {
      class: self.class.name,
      message: message,
      code: code,
      details: details
    }
    hash[:caused_by] = caused_by.to_h if caused_by.is_a?(ApplicationError)
    hash
  end
end
