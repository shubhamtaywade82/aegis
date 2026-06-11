# frozen_string_literal: true

require "openssl"
require "faraday"
require "json"

module Exchanges
  module CoinDCX
    class RestClient
      attr_reader :api_key, :api_secret, :base_url

      def initialize(api_key: nil, api_secret: nil, base_url: "https://api.coindcx.com")
        @api_key = api_key
        @api_secret = api_secret
        @base_url = base_url
      end

      def request(method, path, body = {})
        timestamp = Time.now.to_i * 1000
        payload = body.merge(timestamp: timestamp)
        json_payload = JSON.generate(payload)

        signature = OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest.new("sha256"),
          api_secret.to_s,
          json_payload
        )

        headers = {
          "X-AUTH-APIKEY" => api_key.to_s,
          "X-AUTH-SIGNATURE" => signature,
          "Content-Type" => "application/json"
        }

        { success: true, path: path, method: method, headers: headers }
      end
    end
  end
end
