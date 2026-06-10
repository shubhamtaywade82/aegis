# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/config/settings'
require_relative '../../app/config/binance_settings'
require_relative '../../app/errors/configuration_error'

RSpec.describe BinanceSettings do
  describe 'valid instantiation' do
    it 'creates an instance with all required fields' do
      instance = described_class.new(
        api_key: 'test_api_key_123',
        api_secret: 'test_secret_456',
        base_url: 'https://api.binance.com',
        testnet: false,
        recv_window: 5000
      )

      expect(instance.api_key).to eq('test_api_key_123')
      expect(instance.api_secret).to eq('test_secret_456')
      expect(instance.base_url).to eq('https://api.binance.com')
      expect(instance.testnet).to eq(false)
      expect(instance.recv_window).to eq(5000)
    end

    it 'accepts string values that get cast to appropriate types' do
      instance = described_class.new(
        api_key: 'key',
        api_secret: 'secret',
        base_url: 'https://api.binance.com',
        testnet: 'true',
        recv_window: '3000'
      )

      expect(instance.testnet).to eq(true)
      expect(instance.recv_window).to eq(3000)
    end

    it 'accepts testnet URL' do
      instance = described_class.new(
        api_key: 'testnet_key',
        api_secret: 'testnet_secret',
        base_url: 'https://testnet.binance.vision',
        testnet: true,
        recv_window: 5000
      )

      expect(instance.base_url).to eq('https://testnet.binance.vision')
      expect(instance.testnet).to eq(true)
    end
  end

  describe '#to_h' do
    it 'returns correct keys' do
      instance = described_class.new(
        api_key: 'key',
        api_secret: 'secret',
        base_url: 'https://api.binance.com',
        testnet: false,
        recv_window: 5000
      )

      hash = instance.to_h

      expect(hash).to include(:api_key, :api_secret, :base_url, :testnet, :recv_window)
      expect(hash[:api_key]).to eq('key')
      expect(hash[:api_secret]).to eq('secret')
      expect(hash[:base_url]).to eq('https://api.binance.com')
      expect(hash[:testnet]).to eq(false)
      expect(hash[:recv_window]).to eq(5000)
    end
  end

  describe 'instance is frozen' do
    it 'freezes the instance after initialization' do
      instance = described_class.new(
        api_key: 'key',
        api_secret: 'secret',
        base_url: 'https://api.binance.com',
        testnet: false,
        recv_window: 5000
      )

      expect(instance).to be_frozen
    end
  end

  describe '#validate!' do
    context 'when api_key is empty' do
      it 'raises ConfigurationError' do
        expect {
          described_class.new(
            api_key: '',
            api_secret: 'secret',
            base_url: 'https://api.binance.com',
            testnet: false,
            recv_window: 5000
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('BINANCE_API_KEY_EMPTY')
        end
      end
    end

    context 'when api_key is nil' do
      it 'raises ConfigurationError' do
        expect {
          described_class.new(
            api_key: nil,
            api_secret: 'secret',
            base_url: 'https://api.binance.com',
            testnet: false,
            recv_window: 5000
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('BINANCE_API_KEY_EMPTY')
        end
      end
    end

    context 'when api_key is only whitespace' do
      it 'raises ConfigurationError' do
        expect {
          described_class.new(
            api_key: '   ',
            api_secret: 'secret',
            base_url: 'https://api.binance.com',
            testnet: false,
            recv_window: 5000
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('BINANCE_API_KEY_EMPTY')
        end
      end
    end

    context 'when api_secret is empty' do
      it 'raises ConfigurationError' do
        expect {
          described_class.new(
            api_key: 'key',
            api_secret: '',
            base_url: 'https://api.binance.com',
            testnet: false,
            recv_window: 5000
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('BINANCE_API_SECRET_EMPTY')
        end
      end
    end

    context 'when api_secret is nil' do
      it 'raises ConfigurationError' do
        expect {
          described_class.new(
            api_key: 'key',
            api_secret: nil,
            base_url: 'https://api.binance.com',
            testnet: false,
            recv_window: 5000
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('BINANCE_API_SECRET_EMPTY')
        end
      end
    end

    context 'when base_url is not a valid HTTP(S) URI' do
      it 'raises ConfigurationError for invalid URI' do
        expect {
          described_class.new(
            api_key: 'key',
            api_secret: 'secret',
            base_url: 'not-a-uri',
            testnet: false,
            recv_window: 5000
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('BINANCE_BASE_URL_INVALID')
        end
      end

      it 'raises ConfigurationError for FTP URI' do
        expect {
          described_class.new(
            api_key: 'key',
            api_secret: 'secret',
            base_url: 'ftp://api.binance.com',
            testnet: false,
            recv_window: 5000
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('BINANCE_BASE_URL_INVALID')
        end
      end

      it 'raises ConfigurationError for WS URI' do
        expect {
          described_class.new(
            api_key: 'key',
            api_secret: 'secret',
            base_url: 'wss://api.binance.com',
            testnet: false,
            recv_window: 5000
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('BINANCE_BASE_URL_INVALID')
        end
      end

      it 'raises ConfigurationError for empty string' do
        expect {
          described_class.new(
            api_key: 'key',
            api_secret: 'secret',
            base_url: '',
            testnet: false,
            recv_window: 5000
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('BINANCE_BASE_URL_INVALID')
        end
      end
    end

    context 'when recv_window is 0' do
      it 'raises ConfigurationError' do
        expect {
          described_class.new(
            api_key: 'key',
            api_secret: 'secret',
            base_url: 'https://api.binance.com',
            testnet: false,
            recv_window: 0
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('BINANCE_RECV_WINDOW_INVALID')
        end
      end
    end

    context 'when recv_window is negative' do
      it 'raises ConfigurationError' do
        expect {
          described_class.new(
            api_key: 'key',
            api_secret: 'secret',
            base_url: 'https://api.binance.com',
            testnet: false,
            recv_window: -100
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('BINANCE_RECV_WINDOW_INVALID')
        end
      end
    end

    context 'when all fields are valid' do
      it 'does not raise any error' do
        expect {
          described_class.new(
            api_key: 'valid_key',
            api_secret: 'valid_secret',
            base_url: 'https://api.binance.com',
            testnet: false,
            recv_window: 5000
          )
        }.not_to raise_error
      end

      it 'accepts https URL' do
        expect {
          described_class.new(
            api_key: 'key',
            api_secret: 'secret',
            base_url: 'https://testnet.binance.vision',
            testnet: true,
            recv_window: 5000
          )
        }.not_to raise_error
      end

      it 'accepts http URL' do
        expect {
          described_class.new(
            api_key: 'key',
            api_secret: 'secret',
            base_url: 'http://localhost:8080',
            testnet: false,
            recv_window: 5000
          )
        }.not_to raise_error
      end
    end
  end

  describe 'testnet boolean parsing' do
    it 'parses testnet: true from string "true"' do
      instance = described_class.new(
        api_key: 'key',
        api_secret: 'secret',
        base_url: 'https://api.binance.com',
        testnet: 'true',
        recv_window: 5000
      )
      expect(instance.testnet).to eq(true)
    end

    it 'parses testnet: true from string "1"' do
      instance = described_class.new(
        api_key: 'key',
        api_secret: 'secret',
        base_url: 'https://api.binance.com',
        testnet: '1',
        recv_window: 5000
      )
      expect(instance.testnet).to eq(true)
    end

    it 'parses testnet: true from string "yes"' do
      instance = described_class.new(
        api_key: 'key',
        api_secret: 'secret',
        base_url: 'https://api.binance.com',
        testnet: 'yes',
        recv_window: 5000
      )
      expect(instance.testnet).to eq(true)
    end

    it 'parses testnet: false from string "false"' do
      instance = described_class.new(
        api_key: 'key',
        api_secret: 'secret',
        base_url: 'https://api.binance.com',
        testnet: 'false',
        recv_window: 5000
      )
      expect(instance.testnet).to eq(false)
    end

    it 'parses testnet: false from string "0"' do
      instance = described_class.new(
        api_key: 'key',
        api_secret: 'secret',
        base_url: 'https://api.binance.com',
        testnet: '0',
        recv_window: 5000
      )
      expect(instance.testnet).to eq(false)
    end

    it 'parses testnet: false from string "no"' do
      instance = described_class.new(
        api_key: 'key',
        api_secret: 'secret',
        base_url: 'https://api.binance.com',
        testnet: 'no',
        recv_window: 5000
      )
      expect(instance.testnet).to eq(false)
    end
  end
end