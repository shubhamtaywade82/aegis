# frozen_string_literal: true

namespace :trading do
  desc "Starts the live autonomous trading bot daemon"
  task start: :environment do
    # Eagerly load the exchanges namespace
    Dir[Rails.root.join("app/exchanges/**/*.rb")].each { |f| require f }

    Rails.logger.info "[TradingDaemon] Starting autonomous trading bot daemon..."
    puts "Starting autonomous trading daemon..."

    # 1. Initialize settings & validations
    Settings.validate!
    
    # 2. Set up clients and engine adapters
    adapter = Exchanges::Binance::TestnetAdapter.new
    websocket_client = Exchanges::Binance::WebsocketClient.new(ws_url: BinanceSettings.ws_url)

    # 3. Handle connection callbacks
    websocket_client.on(:connected) do |event|
      Rails.logger.info "[TradingDaemon] Connected to Binance WebSocket stream successfully. Subscribing to ETHUSDT & SOLUSDT..."
      puts "Connected to WebSocket stream! Subscribing to ETHUSDT & SOLUSDT..."
      
      subscription_payload = {
        method: "SUBSCRIBE",
        params: ["ethusdt@ticker", "solusdt@ticker"],
        id: 1
      }
      websocket_client.send_json(subscription_payload)
    end

    websocket_client.on(:message) do |data|
      # Ingest ticker updates
      if data && data["e"] == "24hrTicker"
        symbol = data["s"]
        ltp = data["c"]
        Rails.logger.info "[TradingDaemon] Ticker tick received - Symbol: #{symbol}, Price: #{ltp}"
        puts "[TradingDaemon] Ticker tick received - Symbol: #{symbol}, Price: #{ltp}"
        MatchingEngine.process_ticker_tick(symbol, ltp)
      end
    end

    websocket_client.on(:error) do |err|
      Rails.logger.error "[TradingDaemon] WebSocket Error: #{err}"
      puts "WebSocket Error: #{err}"
    end

    websocket_client.on(:disconnected) do |event|
      Rails.logger.warn "[TradingDaemon] WebSocket disconnected. Retrying connection..."
      puts "WebSocket disconnected. Reconnecting..."
      sleep 2
      websocket_client.connect
    end

    # 4. Start event loops inside EventMachine
    websocket_client.connect
  end
end
