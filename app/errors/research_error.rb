# frozen_string_literal: true

require_relative 'application_error'

# Raised when a research / simulation / backtesting operation fails
# (e.g. insufficient data, numerical instability, or walk-forward breach).
class ResearchError < ApplicationError
  def initialize(message = nil, code: :research_error, details: {}, caused_by: nil)
    super(message, code: code, details: details, caused_by: caused_by)
  end
end
