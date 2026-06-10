# frozen_string_literal: true

require "oj"

module Shared
  class StructuredLogger
    def initialize(logger: Rails.logger)
      @logger = logger
    end

    def info(event:, message:, **context)
      log(:info, event, message, context)
    end

    def warn(event:, message:, **context)
      log(:warn, event, message, context)
    end

    def error(event:, message:, **context)
      log(:error, event, message, context)
    end

    private

    attr_reader :logger

    def log(level, event, message, context)
      payload = {
        timestamp: Time.current.iso8601,
        level: level.to_s.upcase,
        event: event,
        message: message,
        context: context
      }

      logger.public_send(level, Oj.dump(payload))
    end
  end
end
