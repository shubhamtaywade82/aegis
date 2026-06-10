# frozen_string_literal: true

require "time"

module Execution
  class EventStore
    attr_reader :events

    def initialize
      @events = []
    end

    def emit(type, data = {})
      event = {
        type: type.to_sym,
        timestamp: Time.now,
        data: data.freeze
      }.freeze
      @events << event
      event
    end

    def find_by_type(type)
      events.select { |e| e[:type] == type.to_sym }
    end

    def clear!
      @events = []
    end

    def to_a
      events
    end

    def serialize
      events.map do |e|
        {
          "type" => e[:type].to_s,
          "timestamp" => e[:timestamp].iso8601(6),
          "data" => stringify_keys(e[:data])
        }
      end
    end

    def restore(array)
      @events = array.map do |e|
        {
          type: e["type"].to_sym,
          timestamp: Time.parse(e["timestamp"]),
          data: symbolize_keys(e["data"])
        }.freeze
      end
    end

    private

    def stringify_keys(hash)
      hash.transform_keys(&:to_s)
    end

    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end
  end
end
