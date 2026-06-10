# frozen_string_literal: true

require_relative 'binance_settings'
require_relative 'research_settings'
require_relative 'telegram_settings'
require_relative 'sidekiq_settings'
require_relative 'redis_settings'

module Settings
  def self.validate!
    Binance.validate!
    Research.validate!
    Telegram.validate!
    Sidekiq.validate!
    Redis.validate!
  end
end