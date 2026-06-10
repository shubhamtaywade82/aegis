# frozen_string_literal: true

require 'uri'
require_relative 'settings'

class BinanceSettings < Settings
  string  :api_key
  string  :api_secret
  string  :base_url
  boolean :testnet
  integer :recv_window

  def validate!
    validate_non_empty(:api_key)
    validate_non_empty(:api_secret)
    validate_base_url
    validate_positive(:recv_window)
  end

  private

  def validate_non_empty(field)
    value = public_send(field)
    return unless value.nil? || value.to_s.strip.empty?

    raise ConfigurationError.new(
      "Binance #{field.to_s.tr('_', ' ')} is required and cannot be empty",
      code: "BINANCE_#{field.to_s.upcase}_EMPTY",
      details: { field: field }
    )
  end

  def validate_base_url
    uri = URI.parse(base_url.to_s)
    unless uri.is_a?(URI::HTTPS) || uri.is_a?(URI::HTTP)
      raise ConfigurationError.new(
        "Binance base_url must be a valid HTTP or HTTPS URI, got: #{base_url.inspect}",
        code: 'BINANCE_BASE_URL_INVALID',
        details: { base_url: base_url }
      )
    end
  rescue URI::Error => e
    raise ConfigurationError.new(
      "Binance base_url is not a valid URI: #{e.message}",
      code: 'BINANCE_BASE_URL_INVALID',
      details: { base_url: base_url, error: e.message }
    )
  end

  def validate_positive(field)
    value = public_send(field)
    return if value.to_i > 0

    raise ConfigurationError.new(
      "Binance #{field.to_s.tr('_', ' ')} must be a positive integer, got: #{value.inspect}",
      code: "BINANCE_#{field.to_s.upcase}_INVALID",
      details: { field => value }
    )
  end
end
