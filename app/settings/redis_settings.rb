# frozen_string_literal: true

require "uri"

module RedisSettings
  module_function

  def url
    Settings.env!("REDIS_URL")
  end

  def validate!
    validate_url!

    true
  end

  def validate_url!
    uri = URI.parse(url)

    raise ConfigurationError,
          "REDIS_URL must be a valid URI" unless uri.scheme && uri.host

    true
  rescue URI::InvalidURIError
    raise ConfigurationError,
          "REDIS_URL must be a valid URI"
  end
end