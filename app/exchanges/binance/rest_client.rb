# frozen_string_literal: true

require "faraday"
require "json"
require_relative "client"
require_relative "signer"
require_relative "../../errors/external_service_error"

module Exchanges
  module Binance
    class RestClient < Client
      def initialize(
        api_key: nil,
        api_secret: nil,
        base_url: TESTNET_BASE_URL
      )
        super(
          api_key: api_key || ENV["BINANCE_TESTNET_API_KEY"] || ENV["BINANCE_API_KEY"],
          api_secret: api_secret || ENV["BINANCE_TESTNET_API_SECRET"] || ENV["BINANCE_API_SECRET"]
        )
        @base_url = base_url
        @time_offset = 0
        @last_time_sync = nil
      end

      def signed_request(method, path, params = {})
        ensure_time_sync!

        timestamp = (Time.now.to_f * 1000).to_i + @time_offset
        payload = params.merge(timestamp: timestamp)

        query_string = URI.encode_www_form(payload)
        signature = Signer.sign(secret: api_secret, query_string: query_string)
        query_string += "&signature=#{signature}"

        headers = {
          "X-MBX-APIKEY" => api_key.to_s,
          "Content-Type" => "application/x-www-form-urlencoded"
        }

        response = make_http_call_with_retry(method, path, query_string, headers)

        unless response.success?
          raise ExternalServiceError.new(
            "Binance API Error: #{response.body}",
            service: :binance,
            context: { status: response.status, body: response.body }
          )
        end

        JSON.parse(response.body)
      end

      def public_request(path, params = {})
        response = connection.get(path, params)

        unless response.success?
          raise ExternalServiceError.new(
            "Binance API Error: #{response.body}",
            service: :binance
          )
        end

        JSON.parse(response.body)
      end

      private

      def connection
        @connection ||= Faraday.new(url: @base_url) do |f|
          f.request :url_encoded
          f.adapter Faraday.default_adapter
        end
      end

      def make_http_call_with_retry(method, path, query_string, headers)
        retries = 3
        backoff = 0.5

        begin
          case method.to_sym
          when :get
            connection.get("#{path}?#{query_string}", nil, headers)
          when :post
            connection.post(path, query_string, headers)
          when :delete
            connection.delete("#{path}?#{query_string}", nil, headers)
          end
        rescue Faraday::Error => e
          if retries.positive?
            retries -= 1
            sleep(backoff)
            backoff *= 2
            retry
          else
            raise e
          end
        end
      end

      def ensure_time_sync!
        return if @last_time_sync && (Time.now - @last_time_sync) < 60

        begin
          response = connection.get("/fapi/v1/time")
          if response.success?
            server_time = JSON.parse(response.body)["serverTime"].to_i
            local_time = (Time.now.to_f * 1000).to_i
            @time_offset = server_time - local_time
            @last_time_sync = Time.now
          end
        rescue
          @time_offset = 0
        end
      end
    end
  end
end
