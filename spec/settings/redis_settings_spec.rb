# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/settings/redis_settings'
require_relative '../../app/errors/configuration_error'

RSpec.describe Settings::Redis do
  describe '.url' do
    context 'when REDIS_URL is set to a valid URL' do
      before do
        allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('redis://localhost:6379/0')
      end

      it 'returns the URL' do
        expect(described_class.url).to eq('redis://localhost:6379/0')
      end
    end

    context 'when REDIS_URL is set to a different valid URL' do
      before do
        allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('redis://redis.example.com:6380/1')
      end

      it 'returns the URL' do
        expect(described_class.url).to eq('redis://redis.example.com:6380/1')
      end
    end
  end

  describe '.validate!' do
    context 'when REDIS_URL is valid' do
      before do
        allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('redis://localhost:6379/0')
      end

      it 'does not raise' do
        expect { described_class.validate! }.not_to raise_error
      end
    end

    context 'when REDIS_URL is empty string' do
      before do
        allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /REDIS_URL is required/)
      end
    end

    context 'when REDIS_URL is whitespace-only' do
      before do
        allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('   ')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /REDIS_URL is required/)
      end
    end

    context 'when REDIS_URL is a malformed URI' do
      before do
        allow(ENV).to receive(:fetch).with('REDIS_URL').and_return('not-a-valid-uri')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /REDIS_URL must be a valid URI/)
      end
    end

    context 'when REDIS_URL is missing (KeyError)' do
      before do
        allow(ENV).to receive(:fetch).with('REDIS_URL').and_raise(KeyError.new('key not found'))
      end

      it 'raises KeyError from ENV.fetch' do
        expect { described_class.url }.to raise_error(KeyError)
      end
    end
  end
end