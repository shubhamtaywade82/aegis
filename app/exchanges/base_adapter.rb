# frozen_string_literal: true

module Exchanges
  class BaseAdapter
    def account
      raise NotImplementedError, "#{self.class.name}#account is not implemented"
    end

    def positions
      raise NotImplementedError, "#{self.class.name}#positions is not implemented"
    end

    def open_orders
      raise NotImplementedError, "#{self.class.name}#open_orders is not implemented"
    end

    def place_order(order_request)
      raise NotImplementedError, "#{self.class.name}#place_order is not implemented"
    end

    def cancel_order(symbol:, order_id:)
      raise NotImplementedError, "#{self.class.name}#cancel_order is not implemented"
    end

    def modify_order(...)
      raise NotImplementedError, "#{self.class.name}#modify_order is not implemented"
    end

    def latest_price(symbol)
      raise NotImplementedError, "#{self.class.name}#latest_price is not implemented"
    end
  end
end
