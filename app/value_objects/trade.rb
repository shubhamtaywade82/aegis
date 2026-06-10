# frozen_string_literal: true

class Trade
  attr_reader :symbol,
              :side,
              :entry_time,
              :exit_time,
              :entry_price,
              :exit_price,
              :quantity,
              :fees,
              :reason

  LONG = :long
  SHORT = :short

  def initialize(
    symbol:,
    side:,
    entry_time:,
    exit_time:,
    entry_price:,
    exit_price:,
    quantity:,
    fees:,
    reason:
  )
    @symbol = symbol
    @side = side
    @entry_time = entry_time
    @exit_time = exit_time
    @entry_price = entry_price
    @exit_price = exit_price
    @quantity = quantity
    @fees = fees
    @reason = reason
    freeze
  end

  def pnl
    gross_pnl - fees
  end

  def gross_pnl
    case side
    when LONG
      (exit_price - entry_price) * quantity
    when SHORT
      (entry_price - exit_price) * quantity
    else
      raise ValidationError,
            "Invalid trade side: #{side}"
    end
  end

  def return_pct
    return 0.0 if entry_price.zero?

    (pnl / (entry_price * quantity)) * 100.0
  end

  def winner?
    pnl.positive?
  end

  def loser?
    pnl.negative?
  end

  def duration_seconds
    exit_time.to_i - entry_time.to_i
  end
end
