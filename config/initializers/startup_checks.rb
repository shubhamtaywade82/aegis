# frozen_string_literal: true

Rails.application.config.after_initialize do
  next if Rails.env.test?
  next if defined?(Rake)

  Settings.validate!
rescue ConfigurationError => e
  Kernel.abort("\n=== CONFIGURATION ERROR ===\n#{e.message}\n===========================\n")
end