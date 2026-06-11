# frozen_string_literal: true

require "bigdecimal"

module Capital
  class MarginReservationManager
    attr_reader :reservations

    def initialize
      @reservations = {}
    end

    def reserve!(order_id, amount)
      @reservations[order_id.to_s] = {
        amount: BigDecimal(amount.to_s),
        reserved_at: Time.now
      }
    end

    def release!(order_id)
      removed = @reservations.delete(order_id.to_s)
      removed ? removed[:amount] : BigDecimal("0.0")
    end

    def total_reserved
      @reservations.values.sum { |r| r[:amount] }
    end

    def clear!
      @reservations.clear
    end
  end
end
