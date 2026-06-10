# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/services/shared/retryable'

RSpec.describe Retryable do
  let(:instance) { Class.new { include Retryable }.new }

  describe '#retryable' do
    context 'when the block succeeds on the first try' do
      it 'returns the result without retrying' do
        result = instance.retryable { :success }
        expect(result).to eq(:success)
      end
    end

    context 'when the block fails with a listed exception' do
      it 'retries and eventually succeeds' do
        attempts = 0
        result = instance.retryable(
          max_attempts: 3,
          base_delay: 0.01,
          exponential_backoff: false,
          retry_on: [StandardError]
        ) do
          attempts += 1
          attempts < 3 ? raise(StandardError, 'fail') : :success
        end
        expect(result).to eq(:success)
        expect(attempts).to eq(3)
      end

      it 'yields the attempt number to the block' do
        attempts = []
        instance.retryable(
          max_attempts: 3,
          base_delay: 0.01,
          retry_on: [StandardError]
        ) do |attempt|
          attempts << attempt
          raise StandardError, 'fail' if attempt < 3
          :success
        end
        expect(attempts).to eq([1, 2, 3])
      end
    end

    context 'with exponential backoff' do
      it 'doubles the delay on each retry' do
        delays = []
        allow(Kernel).to receive(:sleep) { |duration| delays << duration }
        attempts = 0

        instance.retryable(
          max_attempts: 4,
          base_delay: 0.1,
          exponential_backoff: true,
          retry_on: [StandardError]
        ) do
          attempts += 1
          raise StandardError, 'fail' if attempts < 4
          :success
        end

        # Delays: 0.1 * 2^0 = 0.1, 0.1 * 2^1 = 0.2, 0.1 * 2^2 = 0.4
        expect(delays).to eq([0.1, 0.2, 0.4])
      end
    end

    context 'when the block fails with a non-listed exception' do
      it 're-raises immediately without retrying' do
        attempts = 0
        expect {
          instance.retryable(
            max_attempts: 3,
            retry_on: [BinanceApiError]
          ) do
            attempts += 1
            raise ArgumentError, 'not retryable'
          end
        }.to raise_error(ArgumentError, 'not retryable')

        expect(attempts).to eq(1)
      end
    end

    context 'when max_attempts is exhausted' do
      it 're-raises the final exception' do
        expect {
          instance.retryable(
            max_attempts: 2,
            base_delay: 0.01,
            retry_on: [StandardError]
          ) do
            raise StandardError, 'persistent failure'
          end
        }.to raise_error(StandardError, 'persistent failure')
      end
    end
  end
end

# Dummy class for testing non-listed exception behavior
class BinanceApiError < StandardError; end