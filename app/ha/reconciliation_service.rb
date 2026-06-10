# frozen_string_literal: true

require "bigdecimal"

module Ha
  class ReconciliationService
    attr_reader :mismatches

    def initialize(exchange_adapter:, database_portfolio:)
      @adapter = exchange_adapter
      @portfolio = database_portfolio
      @mismatches = []
    end

    def reconcile!
      @mismatches.clear

      begin
        exch_account = @adapter.account
        exch_balance = exch_account[:balance]
        local_balance = @portfolio.cash_balance

        if (exch_balance - local_balance).abs > BigDecimal("1.0")
          @mismatches << "Balance mismatch: Exchange balance (#{exch_balance.to_f}) != Local balance (#{local_balance.to_f})"
        end
      rescue StandardError => e
        @mismatches << "Failed to fetch exchange balance: #{e.message}"
      end

      begin
        exch_positions = @adapter.positions
        local_positions = @portfolio.positions

        all_symbols = (exch_positions.map(&:symbol) + local_positions.keys).uniq

        all_symbols.each do |sym|
          exch_pos = exch_positions.find { |p| p.symbol == sym }
          local_pos = local_positions[sym]

          if exch_pos.nil? && local_pos
            @mismatches << "Ghost position detected locally for #{sym}: no matching position on exchange"
          elsif exch_pos && local_pos.nil?
            @mismatches << "Orphan position detected on exchange for #{sym}: not found locally"
          elsif exch_pos && local_pos
            if exch_pos.side.to_sym != local_pos.side.to_sym
              @mismatches << "Position side mismatch for #{sym}: Exchange #{exch_pos.side} != Local #{local_pos.side}"
            end

            qty_diff = (exch_pos.quantity - local_pos.quantity).abs
            if qty_diff > BigDecimal("0.001")
              @mismatches << "Position quantity mismatch for #{sym}: Exchange #{exch_pos.quantity.to_f} != Local #{local_pos.quantity.to_f}"
            end
          end
        end
      rescue StandardError => e
        @mismatches << "Failed to fetch exchange positions: #{e.message}"
      end

      @mismatches.empty?
    end
  end
end
