# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/settings/sidekiq_settings'
require_relative '../../app/errors/configuration_error'

RSpec.describe Settings::Sidekiq do
  describe '.concurrency' do
    context 'when SIDEKIQ_CONCURRENCY is not set (uses default)' do
      before do
        allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('10')
      end

      it 'returns the default value of 10' do
        expect(described_class.concurrency).to eq(10)
      end
    end

    context 'when SIDEKIQ_CONCURRENCY is set to custom value' do
      before do
        allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('25')
      end

      it 'returns the custom value' do
        expect(described_class.concurrency).to eq(25)
      end
    end

    context 'when SIDEKIQ_CONCURRENCY is set to 1' do
      before do
        allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('1')
      end

      it 'returns 1' do
        expect(described_class.concurrency).to eq(1)
      end
    end
  end

  describe '.validate!' do
    context 'when SIDEKIQ_CONCURRENCY is valid default (10)' do
      before do
        allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('10')
      end

      it 'does not raise' do
        expect { described_class.validate! }.not_to raise_error
      end
    end

    context 'when SIDEKIQ_CONCURRENCY is valid custom value (25)' do
      before do
        allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('25')
      end

      it 'does not raise' do
        expect { described_class.validate! }.not_to raise_error
      end
    end

    context 'when SIDEKIQ_CONCURRENCY is zero' do
      before do
        allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('0')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /SIDEKIQ_CONCURRENCY must be greater than 0/)
      end
    end

    context 'when SIDEKIQ_CONCURRENCY is negative' do
      before do
        allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('-5')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /SIDEKIQ_CONCURRENCY must be greater than 0/)
      end
    end

    context 'when SIDEKIQ_CONCURRENCY is non-numeric string' do
      before do
        allow(ENV).to receive(:fetch).with('SIDEKIQ_CONCURRENCY', '10').and_return('invalid')
      end

      it 'raises ArgumentError from Integer()' do
        expect { described_class.concurrency }.to raise_error(ArgumentError)
      end
    end
  end
end