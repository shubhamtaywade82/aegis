# frozen_string_literal: true

module Events
  class EventBus
    def initialize
      @subscribers = Hash.new { |h, k| h[k] = [] }
      @global_subscribers = []
    end

    def subscribe(event_type, &block)
      @subscribers[event_type.to_s] << block
    end

    def subscribe_all(&block)
      @global_subscribers << block
    end

    def publish(event)
      @subscribers[event.type].each { |sub| sub.call(event) }
      @global_subscribers.each { |sub| sub.call(event) }
    end

    def clear!
      @subscribers.clear
      @global_subscribers.clear
    end
  end
end
