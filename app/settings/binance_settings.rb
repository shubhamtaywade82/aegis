# frozen_string_literal: true

require "uri"

module BinanceSettings
  module_function

  def api_key
    Settings.env!("BINANCE_API_KEY")
  end

  def api_secret
    Settings.env!("BINANCE_API_SECRET")
  end

  def base_url
    Settings.env!(
      testnet? ? "BINANCE_TESTNET_BASE_URL" : "BINANCE_BASE_URL"
    )
  end

  def ws_url
    Settings.env!(
      testnet? ? "BINANCE_TESTNET_WS_URL" : "BINANCE_WS_URL"
    )
  end

  def testnet?
    Settings.boolean("BINANCE_TESTNET_ENABLED", false)
  end

  def validate!
    validate_credentials!
    validate_urls!

    true
  end

  def validate_credentials!
    api_key
    api_secret
  end

  def validate_urls!
    validate_url!(base_url)
    validate_url!(ws_url)
  end

  def validate_url!(value)
    uri = URI.parse(value)

    valid = uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS) || uri.scheme == "ws" || uri.scheme == "wss"
    raise ConfigurationError, "Invalid URL: #{value}" unless valid

    true
  rescue URI::InvalidURIError
    raise ConfigurationError,
          "Invalid URL: #{value}"
  end
end
