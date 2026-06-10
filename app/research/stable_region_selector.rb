# frozen_string_literal: true

module Research
  class StableRegionSelector
    STABILITY_FACTOR = 1.5

    def self.call(
      optimization_results:,
      minimum_trades: 20,
      minimum_profit_factor: 1.0
    )
      new(
        optimization_results: optimization_results,
        minimum_trades: minimum_trades,
        minimum_profit_factor: minimum_profit_factor
      ).call
    end

    attr_reader :optimization_results,
                :minimum_trades,
                :minimum_profit_factor

    def initialize(
      optimization_results:,
      minimum_trades:,
      minimum_profit_factor:
    )
      @optimization_results = optimization_results
      @minimum_trades = minimum_trades
      @minimum_profit_factor = minimum_profit_factor
    end

    def call
      matrix = build_matrix

      best_region = nil

      (1..8).each do |i|
        (1..8).each do |j|
          neighborhood =
            neighborhood_results(
              matrix,
              i,
              j
            )

          next unless valid_neighborhood?(neighborhood)

          avg = average_pf(neighborhood)

          std =
            standard_deviation(
              neighborhood,
              avg
            )

          score =
            avg -
            (std * STABILITY_FACTOR)

          region =
            StableRegion.new(
              length: 5 + i,
              multiplier: (1.0 + (j * 0.1)).round(1),
              score: score.round(4),
              average_profit_factor: avg.round(4),
              standard_deviation: std.round(4)
            )

          if best_region.nil? ||
             region.score > best_region.score
            best_region = region
          end
        end
      end

      best_region
    end

    private

    def build_matrix
      matrix =
        Array.new(10) do
          Array.new(10)
        end

      optimization_results.each do |result|
        i = result.length - 5
        j = ((result.multiplier - 1.0) * 10).round

        matrix[i][j] = result
      end

      matrix
    end

    def neighborhood_results(
      matrix,
      i,
      j
    )
      results = []

      (-1..1).each do |di|
        (-1..1).each do |dj|
          results << matrix[i + di][j + dj]
        end
      end

      results
    end

    def valid_neighborhood?(results)
      results.all? do |result|
        result &&
          result.total_trades >= minimum_trades &&
          result.profit_factor >= minimum_profit_factor
      end
    end

    def average_pf(results)
      results.sum(&:profit_factor) /
        results.size.to_f
    end

    def standard_deviation(
      results,
      average
    )
      variance =
        results.sum do |r|
          (r.profit_factor - average)**2
        end / results.size.to_f

      Math.sqrt(variance)
    end
  end
end
