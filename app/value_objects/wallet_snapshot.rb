# frozen_string_literal: true

require "bigdecimal"

class WalletSnapshot
  attr_reader :exchange,
              :wallet_balance,
              :available_balance,
              :total_equity,
              :used_margin,
              :reserved_margin,
              :unrealized_pnl,
              :realized_pnl,
              :updated_at

  def initialize(
    exchange:,
    wallet_balance:,
    available_balance:,
    total_equity:,
    used_margin:,
    reserved_margin:,
    unrealized_pnl:,
    realized_pnl:,
    updated_at: nil
  )
    @exchange = exchange.to_sym
    @wallet_balance = BigDecimal(wallet_balance.to_s)
    @available_balance = BigDecimal(available_balance.to_s)
    @total_equity = BigDecimal(total_equity.to_s)
    @used_margin = BigDecimal(used_margin.to_s)
    @reserved_margin = BigDecimal(reserved_margin.to_s)
    @unrealized_pnl = BigDecimal(unrealized_pnl.to_s)
    @realized_pnl = BigDecimal(realized_pnl.to_s)
    @updated_at = updated_at || Time.now
    freeze
  end
end
