# frozen_string_literal: true

class LedgerEntry < ApplicationRecord
  belongs_to :wallet

  validates :amount, presence: true, numericality: true
  validates :transaction_type, presence: true
end
