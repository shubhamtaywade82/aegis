# frozen_string_literal: true

Rails.application.config.after_initialize do
  Settings.validate!
rescue ConfigurationError => e
  Kernel.abort("\n=== CONFIGURATION ERROR ===\n#{e.message}\n===========================\n")
end