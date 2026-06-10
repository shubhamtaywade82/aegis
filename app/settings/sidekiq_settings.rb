# frozen_string_literal: true

module SidekiqSettings
  DEFAULT_CONCURRENCY = 10

  module_function

  def concurrency
    Settings.integer("SIDEKIQ_CONCURRENCY", DEFAULT_CONCURRENCY)
  end

  def validate!
    unless concurrency.positive?
      raise ConfigurationError,
            "SIDEKIQ_CONCURRENCY must be greater than 0"
    end

    true
  end
end