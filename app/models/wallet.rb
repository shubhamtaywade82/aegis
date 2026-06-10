# frozen_string_literal: true

class Wallet < ApplicationRecord
  belongs_to :user
  has_many :ledger_entries, dependent: :destroy

  validates :currency, presence: true
  validates :balance_type, inclusion: { in: %w[SPOT FUTURES_COLLATERAL] }
  validates :available_balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :locked_balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
