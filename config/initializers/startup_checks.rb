# frozen_string_literal: true

unless Rails.env.test?
  Rails.application.config.after_initialize do
    next if defined?(Rake)

    Settings.validate!
    TelegramSettings.validate!
    SidekiqSettings.validate!

    Rails.logger.info(
      "[StartupChecks] Configuration validation completed successfully"
    )
  rescue ConfigurationError => e
    Kernel.abort("\n=== CONFIGURATION ERROR ===\n#{e.message}\n===========================\n")
  end
end
