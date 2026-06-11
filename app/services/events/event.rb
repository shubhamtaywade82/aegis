# frozen_string_literal: true

module Events
  class Event
    attr_reader :type, :payload, :occurred_at

    def initialize(type:, payload: {}, occurred_at: nil)
      @type = type.to_s
      @payload = payload.freeze
      @occurred_at = occurred_at || Time.now
      freeze
    end

    def to_h
      {
        type: type,
        payload: payload,
        occurred_at: occurred_at
      }
    end
  end
end
