# frozen_string_literal: true

class ExternalServiceError < ApplicationError
  attr_reader :service

  def initialize(message = nil, service:, **kwargs)
    @service = service

    super(message, **kwargs)
  end
end
