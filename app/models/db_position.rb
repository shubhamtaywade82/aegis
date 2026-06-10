# frozen_string_literal: true

class DbPosition < ApplicationRecord
  belongs_to :user

  validates :symbol, presence: true
  validates :side, inclusion: { in: %w[long short LONG SHORT] }
  validates :leverage, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :size, presence: true, numericality: { greater_than: 0 }
  validates :entry_price, presence: true, numericality: { greater_than: 0 }
  validates :liquidation_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :maintenance_margin, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unrealized_pnl, presence: true, numericality: true
  validates :status, inclusion: { in: %w[open closed liquidated OPEN CLOSED LIQUIDATED] }
end
