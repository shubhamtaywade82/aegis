# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/value_objects/fee_model"
require_relative "../../app/value_objects/slippage_model"
require_relative "../../app/value_objects/funding_model"
require_relative "../../app/value_objects/latency_model"

RSpec.describe "Execution Models" do
  describe FeeModel do
    it "calculates maker fees correctly" do
      model = described_class.new(mode: :maker, maker_fee: 0.0002)
      fee = model.calculate(entry_notional: 1000.0, exit_notional: 1000.0)
      expect(fee.to_f).to eq(0.4)
    end

    it "calculates taker fees correctly" do
      model = described_class.new(mode: :taker, taker_fee: 0.0005)
      fee = model.calculate(entry_notional: 1000.0, exit_notional: 1000.0)
      expect(fee.to_f).to eq(1.0)
    end
  end

  describe SlippageModel do
    context "fixed mode" do
      let(:model) { described_class.new(mode: :fixed, bps: 10.0) }

      it "applies buy-side entry slippage (adds adjustment)" do
        price = model.apply(price: 100.0, side: :long, transaction_type: :entry)
        expect(price.to_f).to eq(100.1)
      end

      it "applies sell-side entry slippage (subtracts adjustment)" do
        price = model.apply(price: 100.0, side: :short, transaction_type: :entry)
        expect(price.to_f).to eq(99.9)
      end

      it "applies buy-side exit slippage (adds adjustment)" do
        price = model.apply(price: 100.0, side: :short, transaction_type: :exit)
        expect(price.to_f).to eq(100.1)
      end

      it "applies sell-side exit slippage (subtracts adjustment)" do
        price = model.apply(price: 100.0, side: :long, transaction_type: :exit)
        expect(price.to_f).to eq(99.9)
      end
    end

    context "atr mode" do
      let(:model) { described_class.new(mode: :atr, atr_multiplier: 1.5) }

      it "raises error if ATR is missing" do
        expect {
          model.apply(price: 100.0, side: :long, transaction_type: :entry)
        }.to raise_error(ArgumentError, /ATR is required/)
      end

      it "applies slippage using ATR values" do
        price = model.apply(price: 100.0, side: :long, transaction_type: :entry, atr: 2.0)
        expect(price.to_f).to eq(103.0)
      end
    end
  end

  describe FundingModel do
    it "calculates correct intervals and cost" do
      model = described_class.new(rate: 0.0001, interval_hours: 8)
      # 16 hours duration = 2 intervals
      cost = model.cost(notional: 10_000.0, duration_seconds: 16 * 3600)
      expect(cost.to_f).to eq(2.0)
    end

    it "supports continuous hours if interval_hours is zero" do
      model = described_class.new(rate: 0.0001, interval_hours: 0)
      # 2.5 hours duration
      cost = model.cost(notional: 10_000.0, duration_seconds: 2.5 * 3600)
      expect(cost.to_f).to eq(2.5)
    end
  end

  describe LatencyModel do
    let(:model) { described_class.new(mode: :constant, delay_seconds: 15.0) }

    it "calculates delayed timestamp" do
      time = Time.at(1000)
      expect(model.delayed_time(time)).to eq(Time.at(1015))
    end

    it "calculates delayed candle indexes" do
      # 15s delay / 10s interval = 2 bars delay
      index = model.delayed_index(5, interval_seconds: 10, max_index: 10)
      expect(index).to eq(7)
    end

    it "caps the delayed index at the maximum index" do
      index = model.delayed_index(9, interval_seconds: 10, max_index: 10)
      expect(index).to eq(10)
    end
  end
end
