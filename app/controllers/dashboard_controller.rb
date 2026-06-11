# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @symbol = (params[:symbol] || "BTCUSDT").upcase
    @latest_tick = MarketDataFeed.latest_tick(@symbol)
    @latest_kline = MarketDataFeed.latest_kline(@symbol)
    @supertrend = RealtimeSupertrend.latest_for(@symbol)

    # Find or create a default user and wallet for development/paper trading
    user = User.first_or_create!(email: "default@aegis.com")
    wallet = user.wallets.find_or_create_by!(currency: "USDT", balance_type: "FUTURES_COLLATERAL") do |w|
      w.available_balance = BigDecimal("10000.00")
      w.locked_balance = BigDecimal("0.0")
    end

    # Fetch open positions
    open_positions = user.db_positions.where(status: "open")

    @positions = {}
    total_unrealized_pnl = BigDecimal("0.0")

    open_positions.each do |pos|
      sym = pos.symbol
      tick = MarketDataFeed.latest_tick(sym)
      mark_price = tick ? BigDecimal(tick["c"]) : pos.entry_price

      # Calculate unrealized PnL
      pnl = if pos.side.to_s.downcase == "long" || pos.side.to_s.downcase == "buy"
              (mark_price - pos.entry_price) * pos.size
            else
              (pos.entry_price - mark_price) * pos.size
            end

      # Update position's cached PnL in database if it changed significantly
      if (pos.unrealized_pnl - pnl).abs > 0.0001
        pos.update!(unrealized_pnl: pnl)
      end

      total_unrealized_pnl += pnl

      @positions[sym] = {
        "side" => pos.side,
        "quantity" => pos.size,
        "entry_price" => pos.entry_price,
        "mark_price" => mark_price,
        "unrealized_pnl" => pnl,
        "leverage" => pos.leverage
      }
    end

    # Calculate account metrics
    cash_balance = wallet.available_balance + wallet.locked_balance
    equity = cash_balance + total_unrealized_pnl

    @account = {
      "cash_balance" => cash_balance,
      "equity" => equity,
      "unrealized_pnl" => total_unrealized_pnl,
      "used_margin" => wallet.locked_balance,
      "available_margin" => wallet.available_balance,
      "leverage" => open_positions.first&.leverage || 1
    }
  end
end
