# frozen_string_literal: true

require_relative './json_parser'

# JSON structured logger that wraps Rails.logger or a custom IO output.
# Merges constructor params (service, symbol, strategy) into every payload.
class StructuredLogger
  attr_reader :service, :symbol, :strategy

  # @param output [IO, nil] Custom IO for log output (defaults to Rails.logger)
  # @param service [String, nil] Service name merged into every log payload
  # @param symbol [String, nil] Symbol/trading pair merged into every log payload
  # @param strategy [String, nil] Strategy name merged into every log payload
  def initialize(output: nil, service: nil, symbol: nil, strategy: nil)
    @output = output
    @service = service
    @symbol = symbol
    @strategy = strategy
  end

  # @param event [String] (required) Event name for the log entry
  # @param message [String] Human-readable message
  # @param level [String] Log level (debug, info, warn, error, fatal)
  # @param context [Hash] Additional context to merge into payload
  def log(event:, message: nil, level: 'info', **context)
    raise ArgumentError, 'event is required and must be a String' unless event.is_a?(String)

    payload = {
      timestamp: Time.now.utc.iso8601,
      level: level,
      event: event,
      service: service,
      symbol: symbol,
      strategy: strategy,
      message: message
    }.compact.merge(context)

    write_log(payload)
  end

  def debug(event:, message: nil, **context)
    log(event: event, message: message, level: 'debug', **context)
  end

  def info(event:, message: nil, **context)
    log(event: event, message: message, level: 'info', **context)
  end

  def warn(event:, message: nil, **context)
    log(event: event, message: message, level: 'warn', **context)
  end

  def error(event:, message: nil, **context)
    log(event: event, message: message, level: 'error', **context)
  end

  def fatal(event:, message: nil, **context)
    log(event: event, message: message, level: 'fatal', **context)
  end

  private

  def write_log(payload)
    json = JsonParser.dump(payload)
    if @output
      @output.puts(json)
    else
      Rails.logger.info(json)
    end
  rescue StandardError
    # Silently rescue any JSON/log failures to avoid crashing on log failures
  end
end