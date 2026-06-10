# frozen_string_literal: true

require "rails_helper"

RSpec.describe Research::VariantSimulator do
  SupertrendResult = Indicators::Supertrend::Result

  let(:atr_multiplier) { 1.0 }
  let(:reward_risk) { 2.0 }

  subject(:simulator) do
    described_class.new(
      candles: candles,
      supertrend: supertrend,
      atr: atr,
      atr_stop_multiplier: atr_multiplier,
      reward_risk_ratio: reward_risk
    )
  end

  def candle(
    close:,
    high: close,
    low: close,
    time:
  )
    Candle.new(
      open_time: time - 60,
      open: close,
      high: high,
      low: low,
      close: close,
      volume: 1.0,
      close_time: time,
      quote_volume: 0,
      trade_count: 0,
      taker_buy_base_volume: 0,
      taker_buy_quote_volume: 0
    )
  end

  def bullish_st(lower_band: 0)
    SupertrendResult.new(
      value: lower_band,
      direction: :bullish,
      upper_band: nil,
      lower_band: lower_band
    )
  end

  def bearish_st(upper_band: 999)
    SupertrendResult.new(
      value: upper_band,
      direction: :bearish,
      upper_band: upper_band,
      lower_band: nil
    )
  end

  describe "long trades" do
    context "take profit exit" do
      let(:candles) do
        [
          candle(close: 100, time: Time.at(0)),
          candle(close: 100, time: Time.at(60)),
          candle(close: 101, high: 104, low: 100, time: Time.at(120))
        ]
      end

      let(:supertrend) do
        [
          bearish_st,
          bullish_st(lower_band: 95),
          bullish_st(lower_band: 96)
        ]
      end

      let(:atr) { [nil, 1.0, 1.0] }

      it "exits at take profit" do
        trades = simulator.call

        expect(trades.size).to eq(1)

        trade = trades.first

        expect(trade.side).to eq(:long)
        expect(trade.reason).to eq("take_profit")
        expect(trade.entry_price).to eq(100)

        # stop = 99
        # risk = 1
        # tp = 102
        expect(trade.exit_price).to eq(102)
      end
    end

    context "atr stop exit" do
      let(:candles) do
        [
          candle(close: 100, time: Time.at(0)),
          candle(close: 100, time: Time.at(60)),
          candle(close: 101, high: 101, low: 98, time: Time.at(120))
        ]
      end

      let(:supertrend) do
        [
          bearish_st,
          bullish_st(lower_band: 95),
          bullish_st(lower_band: 96)
        ]
      end

      let(:atr) { [nil, 1.0, 1.0] }

      it "exits at stop" do
        trade = simulator.call.first

        expect(trade.reason).to eq("atr_stop")
        expect(trade.exit_price).to eq(99)
      end
    end

    context "opposite flip exit" do
      let(:candles) do
        [
          candle(close: 100, time: Time.at(0)),
          candle(close: 100, time: Time.at(60)),
          candle(close: 101, high: 101, low: 100, time: Time.at(120))
        ]
      end

      let(:supertrend) do
        [
          bearish_st,
          bullish_st(lower_band: 95),
          bearish_st(upper_band: 110)
        ]
      end

      let(:atr) { [nil, 1.0, 1.0] }

      it "exits on opposite flip" do
        trade = simulator.call.first

        expect(trade.reason).to eq("opposite_flip")
        expect(trade.exit_price).to eq(101)
      end
    end
  end

  describe "short trades" do
    context "take profit exit" do
      let(:candles) do
        [
          candle(close: 100, time: Time.at(0)),
          candle(close: 100, time: Time.at(60)),
          candle(close: 99, high: 100, low: 96, time: Time.at(120))
        ]
      end

      let(:supertrend) do
        [
          bullish_st,
          bearish_st(upper_band: 105),
          bearish_st(upper_band: 104)
        ]
      end

      let(:atr) { [nil, 1.0, 1.0] }

      it "exits at take profit" do
        trade = simulator.call.first

        expect(trade.side).to eq(:short)
        expect(trade.reason).to eq("take_profit")

        # stop = 101
        # risk = 1
        # tp = 98
        expect(trade.exit_price).to eq(98)
      end
    end

    context "atr stop exit" do
      let(:candles) do
        [
          candle(close: 100, time: Time.at(0)),
          candle(close: 100, time: Time.at(60)),
          candle(close: 99, high: 102, low: 99, time: Time.at(120))
        ]
      end

      let(:supertrend) do
        [
          bullish_st,
          bearish_st(upper_band: 105),
          bearish_st(upper_band: 104)
        ]
      end

      let(:atr) { [nil, 1.0, 1.0] }

      it "exits at stop" do
        trade = simulator.call.first

        expect(trade.reason).to eq("atr_stop")
        expect(trade.exit_price).to eq(101)
      end
    end
  end

  describe "end of series" do
    let(:candles) do
      [
        candle(close: 100, time: Time.at(0)),
        candle(close: 100, time: Time.at(60))
      ]
    end

    let(:supertrend) do
      [
        bearish_st,
        bullish_st(lower_band: 95)
      ]
    end

    let(:atr) { [nil, 1.0] }

    it "closes open trades" do
      trade = simulator.call.first

      expect(trade.reason).to eq("end_of_series")
      expect(trade.exit_price).to eq(100)
    end
  end

  describe "duplicate protection" do
    let(:candles) do
      [
        candle(close: 100, time: Time.at(0)),
        candle(close: 100, time: Time.at(60)),
        candle(close: 101, time: Time.at(120)),
        candle(close: 102, time: Time.at(180))
      ]
    end

    let(:supertrend) do
      [
        bearish_st,
        bullish_st(lower_band: 95),
        bullish_st(lower_band: 96),
        bullish_st(lower_band: 97)
      ]
    end

    let(:atr) { [nil, 1.0, 1.0, 1.0] }

    it "does not open overlapping positions" do
      trades = simulator.call

      expect(trades.size).to eq(1)
    end
  end

  describe "input validation" do
    let(:candles) { [] }
    let(:supertrend) { [] }
    let(:atr) { [1.0] }

    it "validates array sizes" do
      expect do
        simulator
      end.to raise_error(
        ResearchError,
        "candles, supertrend and atr must have equal sizes"
      )
    end
  end
end
