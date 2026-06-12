# frozen_string_literal: true

module Strategy
  class StrategyRunner
    DEFAULT_CHECK_INTERVAL = 10

    attr_reader :strategy, :check_interval_seconds, :thread

    def initialize(strategy:, check_interval_seconds: DEFAULT_CHECK_INTERVAL)
      @strategy = strategy
      @check_interval_seconds = check_interval_seconds
      @running = false
      @mutex = Mutex.new
    end

    # Creates and starts a background thread that polls the strategy.
    # Idempotent: calling start when already running does nothing.
    def start
      @mutex.synchronize do
        return if @running

        @running = true
        @thread = Thread.new do
          while running?
            begin
              strategy.execute
            rescue StandardError => e
              Rails.logger.error "[StrategyRunner] Error during strategy execution: #{e.message}"
            end
            sleep(check_interval_seconds)
          end
        end
      end
    end

    # Signals the background thread to stop and blocks until it exits.
    def stop
      @mutex.synchronize do
        @running = false
      end
      @thread&.join
    end

    # Thread-safe check of running state.
    def running?
      @mutex.synchronize { @running }
    end
  end
end