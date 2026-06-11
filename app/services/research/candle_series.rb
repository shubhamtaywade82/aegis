# frozen_string_literal: true

module Research
  class CandleSeries
    include Enumerable

    attr_reader :candles,
                :opens,
                :highs,
                :lows,
                :closes,
                :volumes,
                :open_times,
                :close_times

    def initialize(candles)
      raise ArgumentError, "candles must be an Array" unless candles.is_a?(Array)

      @candles = candles.freeze
      @opens = @candles.map(&:open).freeze
      @highs = @candles.map(&:high).freeze
      @lows = @candles.map(&:low).freeze
      @closes = @candles.map(&:close).freeze
      @volumes = @candles.map(&:volume).freeze
      @open_times = @candles.map(&:open_time).freeze
      @close_times = @candles.map(&:close_time).freeze
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

    def to_a
      candles.dup
    end
  end
end
