# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @symbol = (params[:symbol] || "BTCUSDT").upcase
    @latest_tick = MarketDataFeed.latest_tick(@symbol)
    @latest_kline = MarketDataFeed.latest_kline(@symbol)
    @supertrend = nil # Filled by Phase 3
    @positions = []
    @account = {}
  end
end
