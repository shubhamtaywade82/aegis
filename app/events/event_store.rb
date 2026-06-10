# frozen_string_literal: true

require_relative "event"

module Events
  class EventStore
    attr_reader :events

    def initialize
      @events = []
    end

    def append(event)
      @events << event
    end

    def query(type: nil, start_time: nil, end_time: nil)
      filtered = @events
      filtered = filtered.select { |e| e.type == type.to_s } if type
      filtered = filtered.select { |e| e.occurred_at >= start_time } if start_time
      filtered = filtered.select { |e| e.occurred_at <= end_time } if end_time
      filtered
    end

    def replay(event_bus)
      @events.each { |e| event_bus.publish(e) }
    end

    def clear!
      @events.clear
    end
  end
end
