# frozen_string_literal: true

require "bigdecimal"
require_relative "../value_objects/allocation_target"

module Portfolio
  class AllocationEngine
    CORRELATION_GROUPS = [
      [ "BTC", "ETH" ],
      [ "SOL", "AVAX", "ADA" ],
      [ "DOGE", "PEPE", "SHIB" ]
    ].freeze

    MAX_INSTRUMENT_WEIGHT = BigDecimal("0.25")
    MAX_EXCHANGE_WEIGHT = BigDecimal("0.70")
    MIN_WEIGHT = BigDecimal("0.05")
    MAX_GROUP_WEIGHT = BigDecimal("0.40")

    def initialize(max_instrument_weight: MAX_INSTRUMENT_WEIGHT, max_exchange_weight: MAX_EXCHANGE_WEIGHT, min_weight: MIN_WEIGHT, max_group_weight: MAX_GROUP_WEIGHT)
      @max_instrument_weight = BigDecimal(max_instrument_weight.to_s)
      @max_exchange_weight = BigDecimal(max_exchange_weight.to_s)
      @min_weight = BigDecimal(min_weight.to_s)
      @max_group_weight = BigDecimal(max_group_weight.to_s)
    end

    def allocate(assets_metadata:, portfolio_snapshot:, risk_percent: BigDecimal("0.005"))
      scores = {}
      total_score = BigDecimal("0.0")

      assets_metadata.each do |meta|
        symbol = meta[:symbol]
        conf = BigDecimal(meta[:confidence].to_s)
        pf = BigDecimal(meta[:execution_pf].to_s)
        pers = BigDecimal((meta[:persistence] || 1.0).to_s)
        atr = BigDecimal(meta[:atr_pct].to_s)

        score = if atr.positive?
                  (conf * pf * pers) / atr
        else
                  BigDecimal("0.0")
        end

        scores[symbol] = score
        total_score += score
      end

      return [] if total_score.zero?

      weights = {}
      scores.each do |symbol, score|
        weights[symbol] = score / total_score
      end

      weights.reject! { |_, w| w < @min_weight }

      sum_weights = weights.values.sum
      return [] if sum_weights.zero?
      weights.transform_values! { |w| w / sum_weights }

      weights.transform_values! { |w| [ w, @max_instrument_weight ].min }

      sum_weights = weights.values.sum
      return [] if sum_weights.zero?
      weights.transform_values! { |w| w / sum_weights }

      CORRELATION_GROUPS.each do |group|
        group_symbols = weights.keys.select { |sym| group.include?(base_asset_of(sym)) }
        group_sum = group_symbols.sum { |sym| weights[sym] }
        if group_sum > @max_group_weight
          scale = @max_group_weight / group_sum
          group_symbols.each do |sym|
            weights[sym] *= scale
          end
        end
      end

      exchange_weights = Hash.new(BigDecimal("0.0"))
      assets_metadata.each do |meta|
        sym = meta[:symbol]
        if weights.key?(sym)
          exchange_weights[meta[:exchange].to_sym] += weights[sym]
        end
      end

      exchange_weights.each do |exch, exch_w|
        if exch_w > @max_exchange_weight
          scale = @max_exchange_weight / exch_w
          assets_metadata.each do |meta|
            sym = meta[:symbol]
            if meta[:exchange].to_sym == exch && weights.key?(sym)
              weights[sym] *= scale
            end
          end
        end
      end

      sum_weights = weights.values.sum
      return [] if sum_weights.zero?

      weights.map do |symbol, w|
        meta = assets_metadata.find { |m| m[:symbol] == symbol }
        exch = meta[:exchange]
        capital = portfolio_snapshot.equity * w
        risk_budget = capital * risk_percent

        AllocationTarget.new(
          symbol: symbol,
          weight: w,
          capital: capital,
          risk_budget: risk_budget,
          exchange: exch
        )
      end
    end

    private

    def base_asset_of(symbol)
      symbol.to_s.sub(/USDT\z/, "")
    end
  end
end
