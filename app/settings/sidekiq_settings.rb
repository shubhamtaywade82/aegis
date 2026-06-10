# frozen_string_literal: true

require_relative '../errors/configuration_error'

module Settings
  class Sidekiq
    class << self
      def concurrency
        Integer(ENV.fetch('SIDEKIQ_CONCURRENCY', '10'))
      end

      def validate!
        errors = []

        errors << 'SIDEKIQ_CONCURRENCY must be greater than 0' unless concurrency > 0

        raise ConfigurationError, errors.join('; ') unless errors.empty?
      end
    end
  end
end