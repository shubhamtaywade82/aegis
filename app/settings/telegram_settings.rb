# frozen_string_literal: true

module TelegramSettings
  module_function

  def bot_token
    Settings.env("TELEGRAM_BOT_TOKEN", "")
  end

  def chat_id
    Settings.env("TELEGRAM_CHAT_ID", "")
  end

  def enabled?
    !Settings.blank?(bot_token) && !Settings.blank?(chat_id)
  end

  def validate!
    token_present = !Settings.blank?(bot_token)
    chat_id_present = !Settings.blank?(chat_id)

    if token_present && !chat_id_present
      raise ConfigurationError,
            "TELEGRAM_CHAT_ID is required when TELEGRAM_BOT_TOKEN is set"
    end

    if chat_id_present && !token_present
      raise ConfigurationError,
            "TELEGRAM_BOT_TOKEN is required when TELEGRAM_CHAT_ID is set"
    end

    true
  end
end