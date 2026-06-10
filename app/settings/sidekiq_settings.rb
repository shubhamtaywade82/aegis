# frozen_string_literal: true

module SidekiqSettings
  DEFAULT_CONCURRENCY = 10

  module_function

  def concurrency
    Settings.integer(
      "SIDEKIQ_CONCURRENCY",
      DEFAULT_CONCURRENCY
    )
  end

  def validate!
    return true if concurrency.positive?

    raise ConfigurationError,
          "SIDEKIQ_CONCURRENCY must be greater than zero"
  end
end
