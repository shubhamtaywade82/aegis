# frozen_string_literal: true

module Settings
  module_function

  def validate!
    BinanceSettings.validate!
    ResearchSettings.validate!

    true
  end

  def env!(key)
    value = ENV[key]

    raise ConfigurationError,
          "Missing required environment variable: #{key}" if blank?(value)

    value
  end

  def env(key, default = nil)
    ENV.fetch(key, default)
  end

  def integer!(key)
    Integer(env!(key))
  rescue ArgumentError
    raise ConfigurationError,
          "Environment variable #{key} must be an integer"
  end

  def integer(key, default)
    Integer(env(key, default))
  rescue ArgumentError
    raise ConfigurationError,
          "Environment variable #{key} must be an integer"
  end

  def float!(key)
    Float(env!(key))
  rescue ArgumentError
    raise ConfigurationError,
          "Environment variable #{key} must be a float"
  end

  def float(key, default)
    Float(env(key, default))
  rescue ArgumentError
    raise ConfigurationError,
          "Environment variable #{key} must be a float"
  end

  def boolean(key, default = false)
    value = env(key)

    return default if blank?(value)

    %w[
      true
      1
      yes
      y
      on
    ].include?(value.to_s.strip.downcase)
  end

  def blank?(value)
    value.nil? || value.to_s.strip.empty?
  end
end