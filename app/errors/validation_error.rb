# frozen_string_literal: true

require_relative 'application_error'

# Raised when input data fails domain validation (e.g. invalid parameter ranges,
# malformed candle data, or strategy precondition failures).
class ValidationError < ApplicationError
  attr_reader :field

  def initialize(
    message = nil,
    code: :validation_error,
    details: {},
    caused_by: nil,
    field: nil
  )
    @field = field
    super(message, code: code, details: details, caused_by: caused_by)
  end

  def to_h
    super.merge(field: field)
  end
end
