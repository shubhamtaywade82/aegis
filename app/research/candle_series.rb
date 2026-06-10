# frozen_string_literal: true

module Research
  class CandleSeries
    include Enumerable

    attr_reader :candles

    def initialize(candles)
      raise ArgumentError, "candles must be an Array" unless candles.is_a?(Array)

      @candles = candles.freeze
      freeze
    end

    def each(&block)
      candles.each(&block)
    end

    def size
      candles.size
    end

    def empty?
      candles.empty?
    end

    def first
      candles.first
    end

    def last
      candles.last
    end

    def [](index)
      candles[index]
    end

    def slice(start_index, length = nil)
      sliced =
        if length.nil?
          candles.slice(start_index)
        else
          candles.slice(start_index, length)
        end

      self.class.new(Array(sliced))
    end

    def window(size)
      return enum_for(:window, size) unless block_given?

      candles.each_cons(size) do |window|
        yield self.class.new(window)
      end
    end

    def opens
      @opens ||= candles.map(&:open).freeze
    end

    def highs
      @highs ||= candles.map(&:high).freeze
    end

    def lows
      @lows ||= candles.map(&:low).freeze
    end

    def closes
      @closes ||= candles.map(&:close).freeze
    end

    def volumes
      @volumes ||= candles.map(&:volume).freeze
    end

    def open_times
      @open_times ||= candles.map(&:open_time).freeze
    end

    def close_times
      @close_times ||= candles.map(&:close_time).freeze
    end

    def to_a
      candles.dup
    end
  end
end
