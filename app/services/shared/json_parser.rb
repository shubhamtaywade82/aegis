# frozen_string_literal: true

require 'oj'

require_relative '../../errors/validation_error'

# Thin wrapper around OJ with strict mode for JSON serialization/deserialization.
module JsonParser
  # Dump an object to a JSON string.
  #
  # @param obj [Object] The object to serialize
  # @return [String] JSON string representation
  def self.dump(obj)
    Oj.dump(obj, mode: :compat, time_format: :ruby)
  end

  # Load a JSON string into a Ruby object.
  #
  # @param str [String] The JSON string to parse
  # @param symbol_keys [Boolean] Whether to convert keys to symbols (default: true)
  # @return [Hash, Array, Object] Parsed object
  # @raise [ValidationError] On parse failure
  def self.load(str, symbol_keys: true)
    Oj.load(str, symbol_keys: symbol_keys, mode: :strict)
  rescue Oj::ParseError, StandardError => e
    raise ValidationError.new(
      "JSON parse error: #{e.message}",
      details: { json: str },
      caused_by: e
    )
  end
end