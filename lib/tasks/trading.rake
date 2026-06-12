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

    # 3. Initialize the strategy pipeline
    paper_engine = Execution::PaperEngine.new(initial_balance: 100_000.0)
    risk_engine = Execution::RiskEngine.new(
      max_positions: 3,
      max_exposure: 0.50,
      max_leverage: 5
    )
    execution_engine = Execution::ExecutionEngine.new(
      adapter: paper_engine,
      risk_engine: risk_engine
    )
    strategy = Strategy::SupertrendStrategy.new(
      symbols: feed.symbols,
      paper_engine: paper_engine,
      execution_engine: execution_engine,
      signal_monitor: Strategy::SignalMonitor.new,
      position_tracker: Strategy::PositionTracker.new,
      order_generator: Strategy::OrderGenerator.new(paper_engine: paper_engine)
    )
    runner = Strategy::StrategyRunner.new(strategy: strategy, check_interval_seconds: 10)

    # 4. Handle SIGTERM for clean shutdown (docker stop, Ctrl+C)
    Signal.trap("TERM") do
      Rails.logger.info "[TradingDaemon] Received TERM signal, shutting down gracefully..."
      puts "Shutting down gracefully..."
      runner.stop
      feed.stop
      exit
    end

    Signal.trap("INT") do
      Rails.logger.info "[TradingDaemon] Received INT signal, shutting down gracefully..."
      puts "Shutting down gracefully..."
      runner.stop
      feed.stop
      exit
    end

    # 5. Start strategy runner in a background thread
    runner.start

    # 6. Start the market data feed
    feed.start

    # 7. Keep the process running
    sleep
  end
end
