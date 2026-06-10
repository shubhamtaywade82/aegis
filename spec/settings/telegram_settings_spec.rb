# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/settings/telegram_settings'
require_relative '../../app/errors/configuration_error'

RSpec.describe Settings::Telegram do
  describe '.bot_token' do
    context 'when TELEGRAM_BOT_TOKEN is set' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('test_bot_token')
      end

      it 'returns the bot token' do
        expect(described_class.bot_token).to eq('test_bot_token')
      end
    end

    context 'when TELEGRAM_BOT_TOKEN is not set' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('')
      end

      it 'returns empty string' do
        expect(described_class.bot_token).to eq('')
      end
    end
  end

  describe '.chat_id' do
    context 'when TELEGRAM_CHAT_ID is set' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('123456789')
      end

      it 'returns the chat ID' do
        expect(described_class.chat_id).to eq('123456789')
      end
    end

    context 'when TELEGRAM_CHAT_ID is not set' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('')
      end

      it 'returns empty string' do
        expect(described_class.chat_id).to eq('')
      end
    end
  end

  describe '.enabled?' do
    context 'when both bot_token and chat_id are present' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('test_bot_token')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('123456789')
      end

      it 'returns true' do
        expect(described_class.enabled?).to eq(true)
      end
    end

    context 'when both bot_token and chat_id are empty' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('')
      end

      it 'returns false' do
        expect(described_class.enabled?).to eq(false)
      end
    end

    context 'when only bot_token is present' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('test_bot_token')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('')
      end

      it 'returns false' do
        expect(described_class.enabled?).to eq(false)
      end
    end

    context 'when only chat_id is present' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('123456789')
      end

      it 'returns false' do
        expect(described_class.enabled?).to eq(false)
      end
    end

    context 'when bot_token and chat_id are whitespace-only' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('   ')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('   ')
      end

      it 'returns false' do
        expect(described_class.enabled?).to eq(false)
      end
    end
  end

  describe '.validate!' do
    context 'when both bot_token and chat_id are empty (disabled state)' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('')
      end

      it 'does not raise' do
        expect { described_class.validate! }.not_to raise_error
      end
    end

    context 'when both bot_token and chat_id are present (enabled state)' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('test_bot_token')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('123456789')
      end

      it 'does not raise' do
        expect { described_class.validate! }.not_to raise_error
      end
    end

    context 'when bot_token is present but chat_id is missing/empty' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('test_bot_token')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /TELEGRAM_CHAT_ID is required/)
      end
    end

    context 'when chat_id is present but bot_token is missing/empty' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('123456789')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /TELEGRAM_BOT_TOKEN is required/)
      end
    end

    context 'when bot_token is whitespace-only and chat_id is present' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('   ')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('123456789')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /TELEGRAM_BOT_TOKEN is required/)
      end
    end

    context 'when chat_id is whitespace-only and bot_token is present' do
      before do
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('test_bot_token')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('   ')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /TELEGRAM_CHAT_ID is required/)
      end
    end
  end
end