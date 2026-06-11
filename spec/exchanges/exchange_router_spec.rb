# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Multi-Exchange Architecture" do
  let(:coindcx_adapter) { Exchanges::CoinDCX::Adapter.new }
  let(:delta_adapter) { Exchanges::Delta::Adapter.new }
  let(:router) do
    Exchanges::ExchangeRouter.new(
      coindcx: coindcx_adapter,
      delta: delta_adapter
    )
  end

  describe Exchanges::ExchangeRouter do
    it "dispatches requests to the correct adapter" do
      acc = router.account(exchange: :coindcx)
      expect(acc[:balance]).to eq(10000.0)

      latest = router.latest_price(exchange: :delta, symbol: "SOLUSDT")
      expect(latest).to eq(100.0)
    end

    it "raises error for unregistered exchange" do
      expect {
        router.account(exchange: :okx)
      }.to raise_error(ArgumentError, /No adapter registered/)
    end
  end

  describe Exchanges::SymbolRegistry do
    it "resolves internal symbol to exchange symbol" do
      expect(Exchanges::SymbolRegistry.resolve(:coindcx, "SOLUSDT")).to eq("B-SOL_USDT")
      expect(Exchanges::SymbolRegistry.resolve(:binance, "SOLUSDT")).to eq("SOLUSDT")
    end

    it "reverse resolves exchange symbol to internal symbol" do
      expect(Exchanges::SymbolRegistry.reverse_resolve(:coindcx, "B-SOL_USDT")).to eq("SOLUSDT")
    end
  end

  describe Exchanges::PrecisionRegistry do
    it "returns correct precision rules" do
      rules = Exchanges::PrecisionRegistry.for(:binance, "SOLUSDT")
      expect(rules[:tick_size]).to eq(0.01)
      expect(rules[:price_precision]).to eq(2)
    end
  end
end
