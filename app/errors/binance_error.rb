# frozen_string_literal: true

class BinanceError < ExternalServiceError
  attr_reader :status, :response_body

  def initialize(
    message = nil,
    status: nil,
    response_body: nil,
    **kwargs
  )
    @status = status
    @response_body = response_body

    super(
      message,
      service: :binance,
      **kwargs
    )
  end
end
