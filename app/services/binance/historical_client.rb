# frozen_string_literal: true

require "faraday"
require_relative "../../settings/binance_settings"
require_relative "../../errors/binance_error"
require_relative "../shared/json_parser"

module Binance
  class HistoricalClient
    def initialize(base_url: BinanceSettings.base_url)
      @base_url = base_url
    end

    def klines(symbol:, interval:, limit: 500, start_time: nil, end_time: nil)
      connection = Faraday.new(url: @base_url) do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end

      params = {
        symbol: symbol,
        interval: interval,
        limit: limit
      }
      params[:startTime] = start_time if start_time
      params[:endTime] = end_time if end_time

      response = connection.get("/fapi/v1/klines", params)

      unless response.success?
        raise BinanceError.new(
          "Failed to fetch klines: #{response.body}",
          status: response.status,
          response_body: response.body
        )
      end

      Shared::JsonParser.load(response.body)
    end
  end
end
