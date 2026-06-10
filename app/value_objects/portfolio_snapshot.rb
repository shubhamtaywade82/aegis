# frozen_string_literal: true

require "bigdecimal"

class PortfolioSnapshot
  attr_reader :cash_balance,
              :equity,
              :used_margin,
              :available_margin,
              :unrealized_pnl,
              :realized_pnl,
              :positions_count

  def initialize(
    cash_balance:,
    equity:,
    used_margin:,
    available_margin:,
    unrealized_pnl:,
    realized_pnl:,
    positions_count:
  )
    @cash_balance = BigDecimal(cash_balance.to_s)
    @equity = BigDecimal(equity.to_s)
    @used_margin = BigDecimal(used_margin.to_s)
    @available_margin = BigDecimal(available_margin.to_s)
    @unrealized_pnl = BigDecimal(unrealized_pnl.to_s)
    @realized_pnl = BigDecimal(realized_pnl.to_s)
    @positions_count = positions_count

    freeze
  end
end
