# frozen_string_literal: true

require_relative '../errors/configuration_error'

module Settings
  class Telegram
    class << self
      def bot_token
        ENV.fetch('TELEGRAM_BOT_TOKEN', '')
      end

      def chat_id
        ENV.fetch('TELEGRAM_CHAT_ID', '')
      end

      def enabled?
        !bot_token.strip.empty? && !chat_id.strip.empty?
      end

      def validate!
        errors = []

        token_present = !bot_token.strip.empty?
        chat_id_present = !chat_id.strip.empty?

        if token_present && !chat_id_present
          errors << 'TELEGRAM_CHAT_ID is required when TELEGRAM_BOT_TOKEN is set'
        end

        if chat_id_present && !token_present
          errors << 'TELEGRAM_BOT_TOKEN is required when TELEGRAM_CHAT_ID is set'
        end

        raise ConfigurationError, errors.join('; ') unless errors.empty?
      end
    end
  end
end