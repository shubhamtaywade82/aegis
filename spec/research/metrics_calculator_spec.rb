# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/research/metrics_calculator"

RSpec.describe Research::MetricsCalculator do
  def build_trade(pnl)
    Trade.new(
      symbol: "BTCUSDT",
      side: :long,
      entry_time: Time.current - 1.hour,
      exit_time: Time.current,
      entry_price: 100,
      exit_price: 100 + pnl,
      quantity: 1.0,
      fees: 0.0,
      reason: pnl.positive? ? "tp" : "sl"
    )
  end

  describe "#call" do
    context "no trades" do
      it "returns a report with empty metrics" do
        report = described_class.new([]).call

        expect(report.total_trades).to eq(0)
        expect(report.net_profit).to eq(0.0)
        expect(report.profit_factor).to eq(0.0)
        expect(report.win_rate).to eq(0.0)
        expect(report.average_trade).to eq(0.0)
        expect(report.max_drawdown).to eq(0.0)
        expect(report.equity_curve).to eq([])
      end
    end

    context "all winners" do
      it "caps profit factor and reward risk at 10_000.0" do
        trades = [build_trade(10.0), build_trade(15.0)]
        report = described_class.new(trades).call

        expect(report.total_trades).to eq(2)
        expect(report.wins).to eq(2)
        expect(report.losses).to eq(0)
        expect(report.profit_factor).to eq(10_000.0)
        expect(report.reward_risk).to eq(10_000.0)
        expect(report.win_rate).to eq(100.0)
      end
    end

    context "all losers" do
      it "has 0.0 profit factor and reward risk" do
        trades = [build_trade(-10.0), build_trade(-15.0)]
        report = described_class.new(trades).call

        expect(report.total_trades).to eq(2)
        expect(report.wins).to eq(0)
        expect(report.losses).to eq(2)
        expect(report.profit_factor).to eq(0.0)
        expect(report.reward_risk).to eq(0.0)
        expect(report.win_rate).to eq(0.0)
      end
    end

    context "mixed trades" do
      it "calculates correct stats" do
        trades = [
          build_trade(20.0),  # Winner
          build_trade(-10.0), # Loser
          build_trade(30.0),  # Winner
          build_trade(-20.0)  # Loser
        ]
        report = described_class.new(trades).call

        expect(report.total_trades).to eq(4)
        expect(report.wins).to eq(2)
        expect(report.losses).to eq(2)
        expect(report.gross_profit).to eq(50.0)
        expect(report.gross_loss).to eq(30.0)
        expect(report.net_profit).to eq(20.0)
        expect(report.profit_factor).to eq(1.6667)
        expect(report.win_rate).to eq(50.0)
        expect(report.average_trade).to eq(5.0)
        expect(report.reward_risk).to eq(1.6667)
      end
    end

    context "drawdown calculation" do
      it "calculates correct absolute maximum drawdown" do
        trades = [
          build_trade(10.0),  # Equity: 10.0 (Peak: 10.0)
          build_trade(-5.0),  # Equity: 5.0  (Peak: 10.0, DD: 5.0)
          build_trade(20.0),  # Equity: 25.0 (Peak: 25.0)
          build_trade(-15.0), # Equity: 10.0 (Peak: 25.0, DD: 15.0)
          build_trade(5.0)    # Equity: 15.0 (Peak: 25.0, DD: 10.0)
        ]
        report = described_class.new(trades).call

        expect(report.equity_curve).to eq([10.0, 5.0, 25.0, 10.0, 15.0])
        expect(report.max_drawdown).to eq(15.0)
      end
    end
  end
end
