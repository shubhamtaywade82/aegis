# frozen_string_literal: true

class ValidationError < ApplicationError
  attr_reader :field

  def initialize(message = nil, field: nil, **kwargs)
    @field = field

    super(message, **kwargs)
  end
end
