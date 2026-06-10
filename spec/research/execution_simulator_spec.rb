# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/research/execution_simulator"
require_relative "../../app/value_objects/fee_model"
require_relative "../../app/value_objects/slippage_model"
require_relative "../../app/value_objects/funding_model"
require_relative "../../app/value_objects/latency_model"

RSpec.describe Research::ExecutionSimulator do
  let(:candles) do
    10.times.map do |i|
      Candle.new(
        open_time: Time.at(i * 3600),
        open: 100.0,
        high: 105.0,
        low: 95.0,
        close: 102.0,
        volume: 1000.0,
        close_time: Time.at((i + 1) * 3600),
        quote_volume: 100000.0,
        trade_count: 50,
        taker_buy_base_volume: 500.0,
        taker_buy_quote_volume: 50000.0
      )
    end
  end

  let(:trade) do
    Trade.new(
      symbol: "SOLUSDT",
      side: :long,
      entry_time: Time.at(1 * 3600),
      exit_time: Time.at(3 * 3600),
      entry_price: 100.0,
      exit_price: 105.0,
      quantity: 10.0,
      fees: 0.0,
      reason: :supertrend_flip
    )
  end

  let(:fee_model) { FeeModel.new(mode: :taker, taker_fee: 0.0005) }
  let(:slippage_model) { SlippageModel.new(mode: :fixed, bps: 10.0) }
  let(:funding_model) { FundingModel.new(rate: 0.0001, interval_hours: 8) }

  describe ".call" do
    it "simulates execution adjustments correctly for a simple long trade" do
      report = described_class.call(
        trades: [ trade ],
        fee_model: fee_model,
        slippage_model: slippage_model,
        funding_model: funding_model
      )

      expect(report).to be_a(ExecutionReport)
      expect(report.gross_net_profit.to_f).to eq(50.0)

      # Slippage:
      # Entry: 100.0 + 10 BPS = 100.1
      # Exit: 105.0 - 10 BPS = 104.895
      # Slippage PnL: (104.895 - 100.1) * 10 = 47.95
      # Slippage Cost: 50.0 - 47.95 = 2.05
      expect(report.slippage_impact.to_f).to eq(2.05)

      # Fees:
      # Entry Notional = 100.1 * 10 = 1001.0
      # Exit Notional = 104.895 * 10 = 1048.95
      # Fee Rate = 0.0005
      # Entry Fee = 1001.0 * 0.0005 = 0.5005
      # Exit Fee = 1048.95 * 0.0005 = 0.524475
      # Total Fees = 1.024975
      expect(report.fee_impact.to_f).to eq(1.024975)

      # Funding:
      # Duration: 2 hours (7200 seconds)
      # Interval: 8 hours
      # Number of intervals: floor(2/8) = 0
      # Funding cost = 0.0
      expect(report.funding_impact.to_f).to eq(0.0)

      # Execution Net Profit: 47.95 - 1.024975 - 0.0 = 46.925025
      expect(report.execution_net_profit.to_f).to eq(46.925025)

      # Degradation: (50.0 - 46.925025) / 50.0 * 100 = 6.15%
      expect(report.degradation_vs_research).to eq(6.15)
    end

    it "applies latency delays to execution price" do
      latency_model = LatencyModel.new(mode: :constant, delay_seconds: 3600)

      report = described_class.call(
        trades: [ trade ],
        fee_model: fee_model,
        slippage_model: slippage_model,
        funding_model: funding_model,
        latency_model: latency_model,
        candles: candles
      )

      # entry index = 1, delayed by 1 bar is index 2, open of candles[2] = 100.0.
      # exit index = 3, delayed by 1 bar is index 4, close of candles[4] = 102.0.
      # Prices: entry = 100.0, exit = 102.0
      # Slippage 10 BPS: entry = 100.1, exit = 101.898
      expect(report.executed_trades.first.executed_entry_price.to_f).to eq(100.1)
      expect(report.executed_trades.first.executed_exit_price.to_f).to eq(101.898)
    end
  end
end
