# frozen_string_literal: true

class RiskManager
  class RiskValidationError < StandardError; end

  MAINTENANCE_MARGIN_RATE = BigDecimal("0.05") # 5% MMR

  def self.validate_and_initialize_order!(user_id:, symbol:, side:, order_type:, quantity:, price:, leverage:, stop_loss: nil)
    new(
      user_id: user_id,
      symbol: symbol,
      side: side,
      order_type: order_type,
      quantity: quantity,
      price: price,
      leverage: leverage,
      stop_loss: stop_loss
    ).validate!
  end

  def initialize(user_id:, symbol:, side:, order_type:, quantity:, price:, leverage:, stop_loss: nil)
    @user_id = user_id
    @symbol = symbol
    @side = side.to_s.upcase
    @order_type = order_type.to_s.upcase
    @qty = BigDecimal(quantity.to_s)
    @price = BigDecimal(price.to_s)
    @leverage = leverage.to_i
    @stop_loss = BigDecimal(stop_loss.to_s) if stop_loss
  end

  def validate!
    if @leverage > 10
      raise RiskValidationError, "Leverage exceeds cap of 10x"
    end

    notional_value = @qty * @price
    required_margin = notional_value / BigDecimal(@leverage.to_s)

    wallet = Wallet.find_by!(
      user_id: @user_id,
      currency: "USDT",
      balance_type: "FUTURES_COLLATERAL"
    )

    if wallet.available_balance < required_margin
      raise RiskValidationError, "Insufficient margin balance. Required: #{required_margin.to_f} USDT, Available: #{wallet.available_balance.to_f} USDT"
    end

    if @stop_loss
      liq_price = calculate_simulated_liquidation_price
      liq_distance = (@price - liq_price).abs
      stop_distance = (@price - @stop_loss).abs

      if liq_distance < (stop_distance * BigDecimal("2.0"))
        raise RiskValidationError, "Liquidation buffer breach: Distance to liquidation must be at least twice the distance to stop-loss."
      end
    end

    true
  end

  private

  def calculate_simulated_liquidation_price
    lev = BigDecimal(@leverage.to_s)
    if @side == "BUY"
      @price * (BigDecimal("1.0") - (BigDecimal("1.0") / lev) + MAINTENANCE_MARGIN_RATE)
    else
      @price * (BigDecimal("1.0") + (BigDecimal("1.0") / lev) - MAINTENANCE_MARGIN_RATE)
    end
  end
end
