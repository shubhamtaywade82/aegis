# frozen_string_literal: true

require_relative 'application_error'

# Raised when environment variables, config files, or runtime settings are
# missing, malformed, or violate domain constraints.
class ConfigurationError < ApplicationError
  def initialize(message = nil, code: :configuration_error, details: {}, caused_by: nil)
    super(message, code: code, details: details, caused_by: caused_by)
  end
end
