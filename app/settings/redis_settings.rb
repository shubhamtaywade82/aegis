# frozen_string_literal: true

require 'uri'
require_relative '../errors/configuration_error'

module Settings
  class Redis
    class << self
      def url
        ENV.fetch('REDIS_URL')
      end

      def validate!
        errors = []

        errors << 'REDIS_URL is required' if url.strip.empty?

        begin
          uri = URI.parse(url)
          errors << 'REDIS_URL must be a valid URI' unless uri.scheme && uri.host
        rescue URI::Error
          errors << 'REDIS_URL must be a valid URI'
        end

        raise ConfigurationError, errors.join('; ') unless errors.empty?
      end
    end
  end
end