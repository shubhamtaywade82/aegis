# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Execution Models" do
  describe FeeModel do
    it "calculates maker fees correctly" do
      model = described_class.new(mode: :maker, maker_fee: 0.0002)
      fee = model.fee(entry_notional: 1000.0, exit_notional: 1000.0)
      expect(fee.to_f).to eq(0.4)
    end

    it "calculates taker fees correctly" do
      model = described_class.new(mode: :taker, taker_fee: 0.0005)
      fee = model.fee(entry_notional: 1000.0, exit_notional: 1000.0)
      expect(fee.to_f).to eq(1.0)
    end
  end

  describe SlippageModel do
    let(:model) { described_class.new(bps: 10.0) }

    it "applies buy slippage (adds adjustment)" do
      price = model.apply(price: 100.0, side: :buy)
      expect(price.to_f).to eq(100.1)
    end

    it "applies sell slippage (subtracts adjustment)" do
      price = model.apply(price: 100.0, side: :sell)
      expect(price.to_f).to eq(99.9)
    end
  end

  describe FundingModel do
    it "calculates cost" do
      model = described_class.new(rate: 0.0001)
      cost = model.cost(notional: 10_000.0)
      expect(cost.to_f).to eq(1.0)
    end
  end

  describe LatencyModel do
    let(:model) { described_class.new(milliseconds: 1000) }

    it "calculates delayed candle indexes" do
      index = model.delayed_index(5, candles: Array.new(10))
      expect(index).to eq(6)
    end
  end
end
