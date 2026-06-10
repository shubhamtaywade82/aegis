# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/settings/settings'
require_relative '../../app/errors/configuration_error'

RSpec.describe Settings do
  describe '.validate!' do
    context 'when all domain settings are valid' do
      before do
        # Binance settings
        allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('live_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_KEY').and_return('testnet_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_SECRET').and_return('testnet_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_BASE_URL').and_return('https://testnet.binancefuture.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_WS_URL').and_return('wss://testnet.binancefuture.com')
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)

        # Research settings
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')

        # Telegram settings (disabled - both empty)
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('')

        # Sidekiq settings (valid)
        allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('10')

        # Redis settings (valid)
        allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('redis://localhost:6379/0')
      end

      it 'does not raise' do
        expect { described_class.validate! }.not_to raise_error
      end
    end

    context 'when Binance settings are invalid' do
      before do
        # Invalid Binance settings - missing api_key
        allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('')
        allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_KEY').and_return('testnet_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_SECRET').and_return('testnet_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_BASE_URL').and_return('https://testnet.binancefuture.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_WS_URL').and_return('wss://testnet.binancefuture.com')
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)

        # Research settings (valid)
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')

        # Telegram settings (disabled - both empty)
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('')

        # Sidekiq settings (valid)
        allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('10')

        # Redis settings (valid)
        allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('redis://localhost:6379/0')
      end

      it 'raises ConfigurationError from Binance' do
        expect { described_class.validate! }.to raise_error(ConfigurationError)
      end
    end

    context 'when Research settings are invalid' do
      before do
        # Binance settings (valid)
        allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('live_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_KEY').and_return('testnet_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_SECRET').and_return('testnet_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_BASE_URL').and_return('https://testnet.binancefuture.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_WS_URL').and_return('wss://testnet.binancefuture.com')
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)

        # Invalid Research settings - optimization_bars <= forward_bars
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')

        # Telegram settings (disabled - both empty)
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('')

        # Sidekiq settings (valid)
        allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('10')

        # Redis settings (valid)
        allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('redis://localhost:6379/0')
      end

      it 'raises ConfigurationError from Research' do
        expect { described_class.validate! }.to raise_error(ConfigurationError)
      end
    end

    context 'when Telegram settings are invalid (partial config)' do
      before do
        # Binance settings (valid)
        allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('live_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_KEY').and_return('testnet_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_SECRET').and_return('testnet_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_BASE_URL').and_return('https://testnet.binancefuture.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_WS_URL').and_return('wss://testnet.binancefuture.com')
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)

        # Research settings (valid)
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')

        # Invalid Telegram settings - only bot_token present
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('test_bot_token')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('')

        # Sidekiq settings (valid)
        allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('10')

        # Redis settings (valid)
        allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('redis://localhost:6379/0')
      end

      it 'raises ConfigurationError from Telegram' do
        expect { described_class.validate! }.to raise_error(ConfigurationError)
      end
    end

    context 'when Sidekiq settings are invalid' do
      before do
        # Binance settings (valid)
        allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('live_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_KEY').and_return('testnet_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_SECRET').and_return('testnet_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_BASE_URL').and_return('https://testnet.binancefuture.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_WS_URL').and_return('wss://testnet.binancefuture.com')
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)

        # Research settings (valid)
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')

        # Telegram settings (disabled - both empty)
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('')

        # Invalid Sidekiq settings - concurrency is zero
        allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('0')

        # Redis settings (valid)
        allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('redis://localhost:6379/0')
      end

      it 'raises ConfigurationError from Sidekiq' do
        expect { described_class.validate! }.to raise_error(ConfigurationError)
      end
    end

    context 'when Redis settings are invalid' do
      before do
        # Binance settings (valid)
        allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('live_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_KEY').and_return('testnet_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_SECRET').and_return('testnet_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_BASE_URL').and_return('https://testnet.binancefuture.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_WS_URL').and_return('wss://testnet.binancefuture.com')
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)

        # Research settings (valid)
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')

        # Telegram settings (disabled - both empty)
        allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('')
        allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('')

        # Sidekiq settings (valid)
        allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('10')

        # Invalid Redis settings - empty URL
        allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('')
      end

      it 'raises ConfigurationError from Redis' do
        expect { described_class.validate! }.to raise_error(ConfigurationError)
      end
    end
  end
end