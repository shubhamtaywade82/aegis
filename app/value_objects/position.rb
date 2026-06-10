# frozen_string_literal: true

class Position < Data.define(
  :symbol,
  :side,
  :entry_time,
  :entry_price,
  :quantity,
  :stop_loss,
  :take_profit,
  :trail_stop
)
  LONG = :long
  SHORT = :short

  def long?
    side == LONG
  end

  def short?
    side == SHORT
  end

  def unrealized_pnl(current_price)
    case side
    when LONG
      (current_price - entry_price) * quantity
    when SHORT
      (entry_price - current_price) * quantity
    else
      raise ValidationError,
            "Invalid position side: #{side}"
    end
  end

  def risk_per_unit
    case side
    when LONG
      entry_price - stop_loss
    when SHORT
      stop_loss - entry_price
    end
  end

  def reward_per_unit
    case side
    when LONG
      take_profit - entry_price
    when SHORT
      entry_price - take_profit
    end
  end

  def reward_risk_ratio
    return 0.0 if risk_per_unit.zero?

    reward_per_unit / risk_per_unit
  end
end
