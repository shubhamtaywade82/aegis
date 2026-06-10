# frozen_string_literal: true

require "oj"

module Shared
  module JsonParser
    module_function

    def dump(object)
      Oj.dump(object, mode: :strict)
    end

    def load(json)
      Oj.load(json, mode: :strict)
    rescue Oj::ParseError => error
      raise ValidationError,
            "Invalid JSON: #{error.message}"
    end
  end
end