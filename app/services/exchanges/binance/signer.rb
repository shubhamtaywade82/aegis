# frozen_string_literal: true

require "openssl"

module Exchanges
  module Binance
    class Signer
      def self.sign(secret:, query_string:)
        OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest.new("sha256"),
          secret.to_s,
          query_string.to_s
        )
      end
    end
  end
end
