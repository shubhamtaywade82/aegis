# frozen_string_literal: true

class User < ApplicationRecord
  has_many :wallets, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :db_positions, dependent: :destroy
end
