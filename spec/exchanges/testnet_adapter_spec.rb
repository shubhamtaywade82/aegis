# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/exchanges/binance/testnet_adapter"

RSpec.describe Exchanges::Binance::TestnetAdapter do
  let(:adapter) do
    described_class.new(
      api_key: "test_key",
      api_secret: "test_secret",
      base_url: "https://testnet.binancefuture.com"
    )
  end

  describe "#latest_price" do
    it "queries ticker price and parses response successfully" do
      response_mock = double(success?: true, body: '{"symbol":"SOLUSDT","price":"140.25"}')
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with("/fapi/v1/ticker/price", { symbol: "SOLUSDT" })
        .and_return(response_mock)

      price = adapter.latest_price("SOLUSDT")
      expect(price.to_f).to eq(140.25)
    end

    it "raises ExternalServiceError when response fails" do
      response_mock = double(success?: false, body: '{"code":-1121,"msg":"Invalid symbol."}')
      allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response_mock)

      expect {
        adapter.latest_price("INVALID")
      }.to raise_error(ExternalServiceError, /Binance API Error/)
    end
  end

  describe "#account" do
    it "executes signed request to retrieve total margin balance" do
      response_mock = double(
        success?: true,
        body: '{"totalMarginBalance":"10250.45","availableBalance":"9500.20","positions":[]}'
      )
      allow(adapter).to receive(:signed_request)
        .with(:get, "/fapi/v2/account")
        .and_return(JSON.parse(response_mock.body))

      acc = adapter.account
      expect(acc[:balance].to_f).to eq(10250.45)
      expect(acc[:available_balance].to_f).to eq(9500.20)
    end
  end
end
