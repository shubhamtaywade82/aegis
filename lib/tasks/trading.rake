# frozen_string_literal: true

namespace :trading do
  desc "Starts the live autonomous trading bot daemon"
  task start: :environment do
    # Eagerly load required files
    Dir[Rails.root.join("app/exchanges/**/*.rb")].each { |f| require f }
    Dir[Rails.root.join("app/services/**/*.rb")].each { |f| require f }
    Dir[Rails.root.join("app/channels/**/*.rb")].each { |f| require f }

    Rails.logger.info "[TradingDaemon] Starting autonomous trading bot daemon..."
    puts "Starting autonomous trading daemon..."

    # 1. Initialize settings & validations
    Settings.validate!

    # 2. Initialize the MarketDataFeed
    feed = MarketDataFeed.new

    # 3. Handle SIGTERM for clean shutdown (docker stop, Ctrl+C)
    Signal.trap("TERM") do
      Rails.logger.info "[TradingDaemon] Received TERM signal, shutting down gracefully..."
      puts "Shutting down gracefully..."
      feed.stop
      exit
    end

    Signal.trap("INT") do
      Rails.logger.info "[TradingDaemon] Received INT signal, shutting down gracefully..."
      puts "Shutting down gracefully..."
      feed.stop
      exit
    end

    # 4. Start the market data feed
    feed.start

    # 5. Keep the process running
    sleep
  end
end
