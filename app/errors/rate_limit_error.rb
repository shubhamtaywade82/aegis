# frozen_string_literal: true

class RateLimitError < BinanceError
  attr_reader :retry_after

  def initialize(message = nil, retry_after: nil, **kwargs)
    @retry_after = retry_after

    super(message, **kwargs)
  end
end
