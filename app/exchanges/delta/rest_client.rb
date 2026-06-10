# frozen_string_literal: true

require "openssl"
require "faraday"
require "json"

module Exchanges
  module Delta
    class RestClient
      attr_reader :api_key, :api_secret, :base_url

      def initialize(api_key: nil, api_secret: nil, base_url: "https://api.delta.exchange")
        @api_key = api_key
        @api_secret = api_secret
        @base_url = base_url
      end

      def request(method, path, body = {})
        timestamp = Time.now.to_i
        payload = body.merge(timestamp: timestamp)
        json_payload = JSON.generate(payload)

        signature = OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest.new("sha256"),
          api_secret.to_s,
          json_payload
        )

        headers = {
          "api-key" => api_key.to_s,
          "signature" => signature,
          "timestamp" => timestamp.to_s,
          "Content-Type" => "application/json"
        }

        { success: true, path: path, method: method, headers: headers }
      end
    end
  end
end
