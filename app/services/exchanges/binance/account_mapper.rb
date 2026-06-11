# frozen_string_literal: true

require "bigdecimal"

module Exchanges
  module Binance
    class AccountMapper
      def self.from_binance(response)
        {
          balance: BigDecimal(response["totalMarginBalance"] || "0.0"),
          available_balance: BigDecimal(response["availableBalance"] || "0.0"),
          positions: response["positions"] || []
        }
      end
    end
  end
end
