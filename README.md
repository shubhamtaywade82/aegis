# Aegis Trading Platform

Aegis is an institutional-grade, multi-exchange algorithmic trading platform built on Ruby on Rails. It includes a comprehensive backtesting engine, walk-forward validation framework, execution simulation (with slippage, fees, funding, and latency), 5-level pre-trade risk engine, and integration with local LLMs (via Ollama) for trade validation and journaling.

## Key Features
* **Adaptive Supertrend Engine**: Real-time Supertrend indicator calculation with Wilder's ATR smoothing and multi-tier exit strategies (ATR Stops, Take Profits, Trailing Stops, Opposite Flips).
* **Execution & Fee Simulation**: Friction models adjusting price for slippage (bps) and accounting for maker/taker fees and funding rates.
* **Risk Engine**: 5-level risk check framework validating Position Limits, Leverage Limits, Portfolio Exposure, Correlation Limits, and Emergency Switches.
* **Research and Optimization**: Event-driven backtesting, parameter grid search optimization, stable region selection, and sliding walk-forward analysis.
* **AI Copilot (Ollama)**: Local LLM integration for trade validation (Risk Officer commentary) and post-trade performance journaling.

---

## Getting Started

### Prerequisites
* Ruby `3.4.2`
* PostgreSQL `17`
* Redis `8`
* [Ollama](https://ollama.com/) (running locally or via configured URL)

### Environment Configuration
Copy the sample environment configuration and customize your API credentials:
```bash
cp .env.example .env
```
Ensure `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `OLLAMA_URL`, and exchange API keys are configured correctly.

### Method 1: Docker Compose (Recommended)
You can boot the full Rails stack, background workers, and datastores using:
```bash
# Build and start services
docker-compose up -d

# Prepare database tables and schemas
docker-compose exec app bin/rails db:prepare
```

### Method 2: Bare Metal
To run the components natively on your system:
```bash
# Install ruby packages
bundle install

# Prepare database
bin/rails db:prepare

# Start the Rails server
bundle exec rails server -b 0.0.0.0 -p 3000

# Start Sidekiq background workers
bundle exec sidekiq
```

---

## Running Tests & Static Analysis
Aegis maintains strict quality standards using RSpec, RuboCop, and Brakeman.

* **Execute the RSpec Test Suite**:
  ```bash
  bundle exec rspec
  ```
  *(SimpleCov coverage statistics are automatically generated in the `coverage/` directory on every test run).*
* **Linting & Style Checks**:
  ```bash
  bundle exec rubocop
  ```
* **Security Scanning**:
  ```bash
  bundle exec brakeman
  ```

---

## Interactive Usage & Scripts

To run backtests or interact with the engine directly, boot the Rails console:
```bash
bundle exec rails console
```

#### Run a Walk-Forward Optimization
```ruby
# Extract a series of Candle objects and pass to the engine
report = Research::WalkForwardEngine.call(candles: my_candle_array)
puts report.summary
```

#### Run a Soak Test Session
```ruby
coordinator = Soak::SoakCoordinator.new
coordinator.start_session!

# Perform operations...

coordinator.stop_session!
report = coordinator.generate_report
puts report.evaluate_certification
```

---

## Platform Audit & Gaps
A formal audit has been conducted on the platform's institutional readiness. The complete findings, gap analysis, and implementation roadmap are documented in:
* [aegis_implementation_audit.md](file:///home/nemesis/.gemini/antigravity-cli/brain/4ea11ffc-6513-4045-a0e6-21e339433830/aegis_implementation_audit.md)
