# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/errors/configuration_error'

RSpec.describe 'startup_checks initializer' do
  let(:initializer_path) { File.expand_path('../../config/initializers/startup_checks.rb', __dir__) }

  describe 'initializer file' do
    it 'exists' do
      expect(File.exist?(initializer_path)).to eq(true)
    end

    it 'contains Settings.validate! call' do
      content = File.read(initializer_path)
      expect(content).to include('Settings.validate!')
    end

    it 'uses after_initialize block' do
      content = File.read(initializer_path)
      expect(content).to include('after_initialize')
    end

    it 'rescues ConfigurationError' do
      content = File.read(initializer_path)
      expect(content).to include('rescue ConfigurationError')
    end

    it 'uses Kernel.abort on ConfigurationError' do
      content = File.read(initializer_path)
      expect(content).to include('Kernel.abort')
    end

    it 'formats abort message with CONFIGURATION ERROR header' do
      content = File.read(initializer_path)
      expect(content).to include('=== CONFIGURATION ERROR ===')
    end
  end

  describe 'Settings.validate! behavior' do
    it 'raises ConfigurationError when Telegram has partial config' do
      # Setup: Binance valid, Research valid, Telegram partial, Sidekiq valid, Redis valid
      allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('live_api_key')
      allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
      allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
      allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
      allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_KEY').and_return('testnet_api_key')
      allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_SECRET').and_return('testnet_api_secret')
      allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_BASE_URL').and_return('https://testnet.binancefuture.com')
      allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_WS_URL').and_return('wss://testnet.binancefuture.com')
      allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)

      allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
      allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
      allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
      allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
      allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')

      allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('partial_token')
      allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('')

      allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('10')
      allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('redis://localhost:6379/0')

      # Require Settings after ENV mocks are set up
      expect {
        require_relative '../../app/settings/settings'
        Settings.validate!
      }.to raise_error(ConfigurationError)
    end

    it 'raises ConfigurationError when Sidekiq concurrency is invalid' do
      allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('live_api_key')
      allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
      allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
      allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
      allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_KEY').and_return('testnet_api_key')
      allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_SECRET').and_return('testnet_api_secret')
      allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_BASE_URL').and_return('https://testnet.binancefuture.com')
      allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_WS_URL').and_return('wss://testnet.binancefuture.com')
      allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)

      allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
      allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
      allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
      allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
      allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')

      allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('')
      allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('')

      allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('0')
      allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('redis://localhost:6379/0')

      expect {
        require_relative '../../app/settings/settings'
        Settings.validate!
      }.to raise_error(ConfigurationError)
    end

    it 'raises ConfigurationError when Redis URL is invalid' do
      allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('live_api_key')
      allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
      allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
      allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
      allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_KEY').and_return('testnet_api_key')
      allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_SECRET').and_return('testnet_api_secret')
      allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_BASE_URL').and_return('https://testnet.binancefuture.com')
      allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_WS_URL').and_return('wss://testnet.binancefuture.com')
      allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)

      allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
      allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
      allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
      allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
      allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')

      allow(ENV).to receive(:fetch).with('TELEGRAM_BOT_TOKEN', '').and_return('')
      allow(ENV).to receive(:fetch).with('TELEGRAM_CHAT_ID', '').and_return('')

      allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('10')
      allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('')

      expect {
        require_relative '../../app/settings/settings'
        Settings.validate!
      }.to raise_error(ConfigurationError)
    end
  end
end