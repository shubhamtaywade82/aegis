# frozen_string_literal: true

require_relative 'application_error'

# Raised when a live trading execution operation fails
# (e.g. order rejection, position mismatch, or circuit-breaker trip).
class ExecutionError < ApplicationError
  def initialize(message = nil, code: :execution_error, details: {}, caused_by: nil)
    super(message, code: code, details: details, caused_by: caused_by)
  end
end
