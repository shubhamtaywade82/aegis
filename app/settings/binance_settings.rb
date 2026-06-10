# frozen_string_literal: true

require 'uri'
require_relative '../errors/configuration_error'

module Settings
  class Binance
    TESTNET_VALUES = %w[true 1 yes].freeze

    class << self
      def testnet?
        value = ENV['BINANCE_TESTNET']
        value.to_s.downcase.match?(/\A(true|1|yes)\z/)
      end

      def api_key
        testnet? ? ENV.fetch('BINANCE_TESTNET_API_KEY') : ENV.fetch('BINANCE_API_KEY')
      end

      def api_secret
        testnet? ? ENV.fetch('BINANCE_TESTNET_API_SECRET') : ENV.fetch('BINANCE_API_SECRET')
      end

      def base_url
        testnet? ? ENV.fetch('BINANCE_TESTNET_BASE_URL') : ENV.fetch('BINANCE_BASE_URL')
      end

      def ws_url
        testnet? ? ENV.fetch('BINANCE_TESTNET_WS_URL') : ENV.fetch('BINANCE_WS_URL')
      end

      def validate!
        errors = []

        errors << 'api_key is required' if api_key.strip.empty?
        errors << 'api_secret is required' if api_secret.strip.empty?

        begin
          uri = URI.parse(base_url)
          errors << 'base_url must be a valid URI' unless uri.is_a?(URI::HTTPS) || uri.is_a?(URI::HTTP)
        rescue URI::Error
          errors << 'base_url must be a valid URI'
        end

        begin
          uri = URI.parse(ws_url)
          errors << 'ws_url must be a valid URI' unless uri.scheme && %w[ws wss http https].include?(uri.scheme.downcase)
        rescue URI::Error
          errors << 'ws_url must be a valid URI'
        end

        raise ConfigurationError, errors.join('; ') unless errors.empty?
      end
    end
  end
end