# frozen_string_literal: true

class FundingModel
  attr_reader :rate

  def initialize(rate:)
    @rate = rate
  end

  def cost(notional:)
    notional * rate
  end
end
