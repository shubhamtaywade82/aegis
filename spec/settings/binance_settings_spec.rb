# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/settings/binance_settings'
require_relative '../../app/errors/configuration_error'

RSpec.describe Settings::Binance do
  let(:valid_live_env) do
    {
      'BINANCE_API_KEY' => 'live_api_key',
      'BINANCE_API_SECRET' => 'live_api_secret',
      'BINANCE_BASE_URL' => 'https://fapi.binance.com',
      'BINANCE_WS_URL' => 'wss://fstream.binance.com',
      'BINANCE_TESTNET_API_KEY' => 'testnet_api_key',
      'BINANCE_TESTNET_API_SECRET' => 'testnet_api_secret',
      'BINANCE_TESTNET_BASE_URL' => 'https://testnet.binancefuture.com',
      'BINANCE_TESTNET_WS_URL' => 'wss://testnet.binancefuture.com'
    }
  end

  describe '.api_key' do
    context 'when live mode (BINANCE_TESTNET not set)' do
      before do
        valid_live_env.each do |key, value|
          allow(ENV).to receive(:fetch).with(key).and_return(value)
        end
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)
      end

      it 'returns the live API key' do
        expect(described_class.api_key).to eq('live_api_key')
      end
    end

    context 'when testnet mode (BINANCE_TESTNET=true)' do
      before do
        valid_live_env.each do |key, value|
          allow(ENV).to receive(:fetch).with(key).and_return(value)
        end
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return('true')
      end

      it 'returns the testnet API key' do
        expect(described_class.api_key).to eq('testnet_api_key')
      end
    end

    context 'when testnet mode (BINANCE_TESTNET=1)' do
      before do
        valid_live_env.each do |key, value|
          allow(ENV).to receive(:fetch).with(key).and_return(value)
        end
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return('1')
      end

      it 'returns the testnet API key' do
        expect(described_class.api_key).to eq('testnet_api_key')
      end
    end

    context 'when testnet mode (BINANCE_TESTNET=yes)' do
      before do
        valid_live_env.each do |key, value|
          allow(ENV).to receive(:fetch).with(key).and_return(value)
        end
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return('yes')
      end

      it 'returns the testnet API key' do
        expect(described_class.api_key).to eq('testnet_api_key')
      end
    end
  end

  describe '.api_secret' do
    context 'when live mode' do
      before do
        valid_live_env.each do |key, value|
          allow(ENV).to receive(:fetch).with(key).and_return(value)
        end
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)
      end

      it 'returns the live API secret' do
        expect(described_class.api_secret).to eq('live_api_secret')
      end
    end

    context 'when testnet mode' do
      before do
        valid_live_env.each do |key, value|
          allow(ENV).to receive(:fetch).with(key).and_return(value)
        end
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return('true')
      end

      it 'returns the testnet API secret' do
        expect(described_class.api_secret).to eq('testnet_api_secret')
      end
    end
  end

  describe '.base_url' do
    context 'when live mode' do
      before do
        valid_live_env.each do |key, value|
          allow(ENV).to receive(:fetch).with(key).and_return(value)
        end
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)
      end

      it 'returns the live base URL' do
        expect(described_class.base_url).to eq('https://fapi.binance.com')
      end
    end

    context 'when testnet mode' do
      before do
        valid_live_env.each do |key, value|
          allow(ENV).to receive(:fetch).with(key).and_return(value)
        end
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return('true')
      end

      it 'returns the testnet base URL' do
        expect(described_class.base_url).to eq('https://testnet.binancefuture.com')
      end
    end
  end

  describe '.ws_url' do
    context 'when live mode' do
      before do
        valid_live_env.each do |key, value|
          allow(ENV).to receive(:fetch).with(key).and_return(value)
        end
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)
      end

      it 'returns the live WS URL' do
        expect(described_class.ws_url).to eq('wss://fstream.binance.com')
      end
    end

    context 'when testnet mode' do
      before do
        valid_live_env.each do |key, value|
          allow(ENV).to receive(:fetch).with(key).and_return(value)
        end
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return('true')
      end

      it 'returns the testnet WS URL' do
        expect(described_class.ws_url).to eq('wss://testnet.binancefuture.com')
      end
    end
  end

  describe '.testnet?' do
    context 'when BINANCE_TESTNET is nil' do
      before do
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)
      end

      it 'returns false' do
        expect(described_class.testnet?).to eq(false)
      end
    end

    context 'when BINANCE_TESTNET is "true"' do
      before do
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return('true')
      end

      it 'returns true' do
        expect(described_class.testnet?).to eq(true)
      end
    end

    context 'when BINANCE_TESTNET is "1"' do
      before do
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return('1')
      end

      it 'returns true' do
        expect(described_class.testnet?).to eq(true)
      end
    end

    context 'when BINANCE_TESTNET is "yes"' do
      before do
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return('yes')
      end

      it 'returns true' do
        expect(described_class.testnet?).to eq(true)
      end
    end

    context 'when BINANCE_TESTNET is "false"' do
      before do
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return('false')
      end

      it 'returns false' do
        expect(described_class.testnet?).to eq(false)
      end
    end

    context 'when BINANCE_TESTNET is "0"' do
      before do
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return('0')
      end

      it 'returns false' do
        expect(described_class.testnet?).to eq(false)
      end
    end

    context 'when BINANCE_TESTNET is "no"' do
      before do
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return('no')
      end

      it 'returns false' do
        expect(described_class.testnet?).to eq(false)
      end
    end
  end

  describe '.validate!' do
    context 'with valid live configuration' do
      before do
        allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('live_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_KEY').and_return('testnet_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_SECRET').and_return('testnet_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_BASE_URL').and_return('https://testnet.binancefuture.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_WS_URL').and_return('wss://testnet.binancefuture.com')
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)
      end

      it 'does not raise' do
        expect { described_class.validate! }.not_to raise_error
      end
    end

    context 'with valid testnet configuration' do
      before do
        allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('live_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_KEY').and_return('testnet_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_API_SECRET').and_return('testnet_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_BASE_URL').and_return('https://testnet.binancefuture.com')
        allow(ENV).to receive(:fetch).with('BINANCE_TESTNET_WS_URL').and_return('wss://testnet.binancefuture.com')
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return('true')
      end

      it 'does not raise' do
        expect { described_class.validate! }.not_to raise_error
      end
    end

    context 'when api_key is missing' do
      before do
        allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_raise(KeyError.new('key not found'))
        allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)
      end

      it 'raises KeyError from ENV.fetch' do
        expect { described_class.api_key }.to raise_error(KeyError)
      end
    end

    context 'when api_key is empty string' do
      before do
        allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('')
        allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /api_key is required/)
      end
    end

    context 'when api_key is whitespace only' do
      before do
        allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('   ')
        allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /api_key is required/)
      end
    end

    context 'when base_url is invalid URI' do
      before do
        allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('live_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('not-a-valid-uri')
        allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('wss://fstream.binance.com')
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /base_url must be a valid URI/)
      end
    end

    context 'when ws_url is invalid URI' do
      before do
        allow(ENV).to receive(:fetch).with('BINANCE_API_KEY').and_return('live_api_key')
        allow(ENV).to receive(:fetch).with('BINANCE_API_SECRET').and_return('live_api_secret')
        allow(ENV).to receive(:fetch).with('BINANCE_BASE_URL').and_return('https://fapi.binance.com')
        allow(ENV).to receive(:fetch).with('BINANCE_WS_URL').and_return('invalid-ws-url')
        allow(ENV).to receive(:[]).with('BINANCE_TESTNET').and_return(nil)
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /ws_url must be a valid URI/)
      end
    end
  end
end