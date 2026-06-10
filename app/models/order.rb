# frozen_string_literal: true

class Order < ApplicationRecord
  belongs_to :user

  validates :client_order_id, presence: true, uniqueness: true
  validates :symbol, presence: true
  validates :side, inclusion: { in: %w[buy sell BUY SELL] }
  validates :order_type, inclusion: { in: %w[market limit stop_market take_profit_market MARKET LIMIT STOP_MARKET TAKE_PROFIT_MARKET] }
  validates :position_effect, inclusion: { in: %w[open close OPEN CLOSE] }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :filled_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validates :leverage, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
end
