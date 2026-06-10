# frozen_string_literal: true

module TelegramSettings
  module_function

  def enabled?
    bot_token_present? || chat_id_present?
  end

  def bot_token
    Settings.env!("TELEGRAM_BOT_TOKEN")
  end

  def chat_id
    Settings.env!("TELEGRAM_CHAT_ID")
  end

  def validate!
    return true unless enabled?

    unless bot_token_present? && chat_id_present?
      raise ConfigurationError,
            "TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must both be configured"
    end

    true
  end

  def bot_token_present?
    !Settings.blank?(ENV["TELEGRAM_BOT_TOKEN"])
  end

  def chat_id_present?
    !Settings.blank?(ENV["TELEGRAM_CHAT_ID"])
  end
end
