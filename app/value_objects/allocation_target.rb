# frozen_string_literal: true

require "bigdecimal"

class AllocationTarget
  attr_reader :symbol, :weight, :capital, :risk_budget, :exchange

  def initialize(symbol:, weight:, capital:, risk_budget:, exchange:)
    @symbol = symbol
    @weight = BigDecimal(weight.to_s)
    @capital = BigDecimal(capital.to_s)
    @risk_budget = BigDecimal(risk_budget.to_s)
    @exchange = exchange.to_sym
    freeze
  end
end
