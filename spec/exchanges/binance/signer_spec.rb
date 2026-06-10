# frozen_string_literal: true

require "rails_helper"
require_relative "../../../app/exchanges/binance/signer"

RSpec.describe Exchanges::Binance::Signer do
  describe ".sign" do
    it "calculates correct HMAC SHA256 signature for a query string" do
      secret = "d5c5896"
      query_string = "symbol=SOLUSDT&side=BUY&type=LIMIT&quantity=1&price=100"

      expected = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        secret,
        query_string
      )

      expect(described_class.sign(secret: secret, query_string: query_string)).to eq(expected)
    end
  end
end
