# frozen_string_literal: true

class TradingChannel < ActionCable::Channel::Base
  # Subscribes to the trading stream for a specific symbol.
  #
  # Expected params:
  #   symbol: String (e.g., "BTCUSDT", "ETHUSDT")
  def subscribed
    stream_from "trading:#{params[:symbol]}"
  end

  # Cleanup when unsubscribing
  def unsubscribed
    # ActionCable handles stream cleanup automatically
  end
end