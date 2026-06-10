# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/settings/research_settings'
require_relative '../../app/errors/configuration_error'

RSpec.describe Settings::Research do
  let(:valid_env) do
    {
      'RESEARCH_OPTIMIZATION_BARS' => '500',
      'RESEARCH_FORWARD_BARS' => '100',
      'RESEARCH_MINIMUM_TRADES' => '30',
      'RESEARCH_ATR_STOP_MULTIPLIER' => '1.5',
      'RESEARCH_REWARD_RISK_RATIO' => '2.0'
    }
  end

  describe '.optimization_bars' do
    context 'with valid integer value' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
      end

      it 'returns the integer value' do
        expect(described_class.optimization_bars).to eq(500)
      end

      it 'returns an Integer' do
        expect(described_class.optimization_bars).to be_a(Integer)
      end
    end

    context 'when value is missing' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_raise(KeyError.new('key not found'))
      end

      it 'raises KeyError from ENV.fetch' do
        expect { described_class.optimization_bars }.to raise_error(KeyError)
      end
    end

    context 'with non-numeric string' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('abc')
      end

      it 'raises ArgumentError from Integer()' do
        expect { described_class.optimization_bars }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.forward_bars' do
    context 'with valid integer value' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
      end

      it 'returns the integer value' do
        expect(described_class.forward_bars).to eq(100)
      end
    end

    context 'with non-numeric string' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('xyz')
      end

      it 'raises ArgumentError from Integer()' do
        expect { described_class.forward_bars }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.minimum_trades' do
    context 'with valid integer value' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
      end

      it 'returns the integer value' do
        expect(described_class.minimum_trades).to eq(30)
      end
    end

    context 'with non-numeric string' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('nan')
      end

      it 'raises ArgumentError from Integer()' do
        expect { described_class.minimum_trades }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.atr_stop_multiplier' do
    context 'with valid float value' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
      end

      it 'returns the float value' do
        expect(described_class.atr_stop_multiplier).to eq(1.5)
      end

      it 'returns a Float' do
        expect(described_class.atr_stop_multiplier).to be_a(Float)
      end
    end

    context 'with non-numeric string' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('NaN')
      end

      it 'raises ArgumentError from Float()' do
        expect { described_class.atr_stop_multiplier }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.reward_risk_ratio' do
    context 'with valid float value' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')
      end

      it 'returns the float value' do
        expect(described_class.reward_risk_ratio).to eq(2.0)
      end
    end

    context 'with non-numeric string' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('inf')
      end

      it 'raises ArgumentError from Float()' do
        expect { described_class.reward_risk_ratio }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.validate!' do
    context 'with valid configuration' do
      before do
        valid_env.each do |key, value|
          allow(ENV).to receive(:fetch).with(key).and_return(value)
        end
      end

      it 'does not raise' do
        expect { described_class.validate! }.not_to raise_error
      end
    end

    context 'when optimization_bars equals forward_bars (boundary)' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /optimization_bars must be greater than forward_bars/)
      end
    end

    context 'when optimization_bars is less than forward_bars' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('50')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /optimization_bars must be greater than forward_bars/)
      end
    end

    context 'when minimum_trades is zero' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('0')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /minimum_trades must be at least 1/)
      end
    end

    context 'when minimum_trades is negative' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('-5')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /minimum_trades must be at least 1/)
      end
    end

    context 'when atr_stop_multiplier is zero' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('0.0')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /atr_stop_multiplier must be greater than 0.0/)
      end
    end

    context 'when atr_stop_multiplier is negative' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('-1.5')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('2.0')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /atr_stop_multiplier must be greater than 0.0/)
      end
    end

    context 'when reward_risk_ratio is zero' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('0.0')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /reward_risk_ratio must be greater than 0.0/)
      end
    end

    context 'when reward_risk_ratio is negative' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('500')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('30')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('1.5')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('-2.0')
      end

      it 'raises ConfigurationError' do
        expect { described_class.validate! }.to raise_error(ConfigurationError, /reward_risk_ratio must be greater than 0.0/)
      end
    end

    context 'when multiple validations fail' do
      before do
        allow(ENV).to receive(:fetch).with('RESEARCH_OPTIMIZATION_BARS').and_return('50')
        allow(ENV).to receive(:fetch).with('RESEARCH_FORWARD_BARS').and_return('100')
        allow(ENV).to receive(:fetch).with('RESEARCH_MINIMUM_TRADES').and_return('0')
        allow(ENV).to receive(:fetch).with('RESEARCH_ATR_STOP_MULTIPLIER').and_return('0.0')
        allow(ENV).to receive(:fetch).with('RESEARCH_REWARD_RISK_RATIO').and_return('0.0')
      end

      it 'raises ConfigurationError with all error messages' do
        expect { described_class.validate! }.to raise_error(ConfigurationError) do |error|
          expect(error.message).to include('optimization_bars must be greater than forward_bars')
          expect(error.message).to include('minimum_trades must be at least 1')
          expect(error.message).to include('atr_stop_multiplier must be greater than 0.0')
          expect(error.message).to include('reward_risk_ratio must be greater than 0.0')
        end
      end
    end
  end
end