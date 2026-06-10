# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/config/settings'
require_relative '../../app/config/research_settings'
require_relative '../../app/errors/configuration_error'

RSpec.describe ResearchSettings do
  describe 'DEFAULTS' do
    it 'has predefined default values' do
      expect(ResearchSettings::DEFAULTS).to include(
        default_lookback: 500,
        optimization_window: 500,
        forward_window: 100,
        stable_region_min_trades: 20,
        stable_region_min_pf: 1.0,
        walk_forward_step: 100
      )
    end
  end

  describe 'valid instantiation' do
    it 'creates an instance with all required fields' do
      instance = described_class.new(
        default_lookback: 600,
        optimization_window: 400,
        forward_window: 100,
        stable_region_min_trades: 30,
        stable_region_min_pf: 1.5,
        walk_forward_step: 50
      )

      expect(instance.default_lookback).to eq(600)
      expect(instance.optimization_window).to eq(400)
      expect(instance.forward_window).to eq(100)
      expect(instance.stable_region_min_trades).to eq(30)
      expect(instance.stable_region_min_pf).to eq(1.5)
      expect(instance.walk_forward_step).to eq(50)
    end

    it 'accepts string values that get cast to appropriate types' do
      instance = described_class.new(
        default_lookback: '600',
        optimization_window: '400',
        forward_window: '100',
        stable_region_min_trades: '30',
        stable_region_min_pf: '1.5',
        walk_forward_step: '50'
      )

      expect(instance.default_lookback).to eq(600)
      expect(instance.optimization_window).to eq(400)
      expect(instance.forward_window).to eq(100)
      expect(instance.stable_region_min_trades).to eq(30)
      expect(instance.stable_region_min_pf).to be_within(0.01).of(1.5)
      expect(instance.walk_forward_step).to eq(50)
    end

    it 'accepts float for stable_region_min_pf' do
      instance = described_class.new(
        default_lookback: 500,
        optimization_window: 500,
        forward_window: 100,
        stable_region_min_trades: 20,
        stable_region_min_pf: 2.5,
        walk_forward_step: 100
      )

      expect(instance.stable_region_min_pf).to eq(2.5)
    end
  end

  describe '#to_h' do
    it 'returns correct keys including float stable_region_min_pf' do
      instance = described_class.new(
        default_lookback: 600,
        optimization_window: 400,
        forward_window: 100,
        stable_region_min_trades: 30,
        stable_region_min_pf: 1.8,
        walk_forward_step: 50
      )

      hash = instance.to_h

      expect(hash).to include(
        :default_lookback,
        :optimization_window,
        :forward_window,
        :stable_region_min_trades,
        :stable_region_min_pf,
        :walk_forward_step
      )
      expect(hash[:default_lookback]).to eq(600)
      expect(hash[:optimization_window]).to eq(400)
      expect(hash[:forward_window]).to eq(100)
      expect(hash[:stable_region_min_trades]).to eq(30)
      expect(hash[:stable_region_min_pf]).to eq(1.8)
      expect(hash[:walk_forward_step]).to eq(50)
    end
  end

  describe 'instance is frozen' do
    it 'freezes the instance after initialization' do
      instance = described_class.new(
        default_lookback: 500,
        optimization_window: 500,
        forward_window: 100,
        stable_region_min_trades: 20,
        stable_region_min_pf: 1.0,
        walk_forward_step: 100
      )

      expect(instance).to be_frozen
    end
  end

  describe '#validate!' do
    context 'when any integer field is 0 or negative' do
      it 'raises ConfigurationError for default_lookback = 0' do
        expect {
          described_class.new(
            default_lookback: 0,
            optimization_window: 500,
            forward_window: 100,
            stable_region_min_trades: 20,
            stable_region_min_pf: 1.0,
            walk_forward_step: 100
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('RESEARCH_DEFAULT_LOOKBACK_INVALID')
        end
      end

      it 'raises ConfigurationError for default_lookback < 0' do
        expect {
          described_class.new(
            default_lookback: -10,
            optimization_window: 500,
            forward_window: 100,
            stable_region_min_trades: 20,
            stable_region_min_pf: 1.0,
            walk_forward_step: 100
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('RESEARCH_DEFAULT_LOOKBACK_INVALID')
        end
      end

      it 'raises ConfigurationError for optimization_window = 0' do
        expect {
          described_class.new(
            default_lookback: 500,
            optimization_window: 0,
            forward_window: 100,
            stable_region_min_trades: 20,
            stable_region_min_pf: 1.0,
            walk_forward_step: 100
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('RESEARCH_OPTIMIZATION_WINDOW_INVALID')
        end
      end

      it 'raises ConfigurationError for forward_window = 0' do
        expect {
          described_class.new(
            default_lookback: 500,
            optimization_window: 500,
            forward_window: 0,
            stable_region_min_trades: 20,
            stable_region_min_pf: 1.0,
            walk_forward_step: 100
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('RESEARCH_FORWARD_WINDOW_INVALID')
        end
      end

      it 'raises ConfigurationError for stable_region_min_trades = 0' do
        expect {
          described_class.new(
            default_lookback: 500,
            optimization_window: 500,
            forward_window: 100,
            stable_region_min_trades: 0,
            stable_region_min_pf: 1.0,
            walk_forward_step: 100
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('RESEARCH_STABLE_REGION_MIN_TRADES_INVALID')
        end
      end

      it 'raises ConfigurationError for walk_forward_step = 0' do
        expect {
          described_class.new(
            default_lookback: 500,
            optimization_window: 500,
            forward_window: 100,
            stable_region_min_trades: 20,
            stable_region_min_pf: 1.0,
            walk_forward_step: 0
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('RESEARCH_WALK_FORWARD_STEP_INVALID')
        end
      end
    end

    context 'when stable_region_min_pf is 0 or negative' do
      it 'raises ConfigurationError for stable_region_min_pf = 0' do
        expect {
          described_class.new(
            default_lookback: 500,
            optimization_window: 500,
            forward_window: 100,
            stable_region_min_trades: 20,
            stable_region_min_pf: 0,
            walk_forward_step: 100
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('RESEARCH_STABLE_REGION_MIN_PF_INVALID')
        end
      end

      it 'raises ConfigurationError for stable_region_min_pf < 0' do
        expect {
          described_class.new(
            default_lookback: 500,
            optimization_window: 500,
            forward_window: 100,
            stable_region_min_trades: 20,
            stable_region_min_pf: -0.5,
            walk_forward_step: 100
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('RESEARCH_STABLE_REGION_MIN_PF_INVALID')
        end
      end
    end

    context 'when optimization_window < forward_window' do
      it 'raises ConfigurationError' do
        expect {
          described_class.new(
            default_lookback: 500,
            optimization_window: 100,
            forward_window: 200,
            stable_region_min_trades: 20,
            stable_region_min_pf: 1.0,
            walk_forward_step: 100
          )
        }.to raise_error(ConfigurationError) do |error|
          expect(error.code).to eq('RESEARCH_WINDOW_INVALID')
          expect(error.message).to include('optimization_window')
          expect(error.message).to include('forward_window')
        end
      end
    end

    context 'when optimization_window equals forward_window' do
      it 'does not raise an error' do
        expect {
          described_class.new(
            default_lookback: 500,
            optimization_window: 100,
            forward_window: 100,
            stable_region_min_trades: 20,
            stable_region_min_pf: 1.0,
            walk_forward_step: 100
          )
        }.not_to raise_error
      end
    end

    context 'when all fields are valid' do
      it 'does not raise any error' do
        expect {
          described_class.new(
            default_lookback: 500,
            optimization_window: 500,
            forward_window: 100,
            stable_region_min_trades: 20,
            stable_region_min_pf: 1.0,
            walk_forward_step: 100
          )
        }.not_to raise_error
      end

      it 'accepts optimization_window > forward_window' do
        expect {
          described_class.new(
            default_lookback: 1000,
            optimization_window: 800,
            forward_window: 200,
            stable_region_min_trades: 30,
            stable_region_min_pf: 1.5,
            walk_forward_step: 50
          )
        }.not_to raise_error
      end
    end
  end

  describe '.from_env' do
    around(:each) do |example|
      # Clean environment before and after each test
      original_env = ENV.to_h.slice(
        'RESEARCH_DEFAULT_LOOKBACK',
        'RESEARCH_OPTIMIZATION_WINDOW',
        'RESEARCH_FORWARD_WINDOW',
        'RESEARCH_STABLE_REGION_MIN_TRADES',
        'RESEARCH_STABLE_REGION_MIN_PF',
        'RESEARCH_WALK_FORWARD_STEP',
        'CUSTOM_DEFAULT_LOOKBACK',
        'CUSTOM_OPTIMIZATION_WINDOW',
        'CUSTOM_FORWARD_WINDOW',
        'CUSTOM_STABLE_REGION_MIN_TRADES',
        'CUSTOM_STABLE_REGION_MIN_PF',
        'CUSTOM_WALK_FORWARD_STEP'
      )

      ENV.delete('RESEARCH_DEFAULT_LOOKBACK')
      ENV.delete('RESEARCH_OPTIMIZATION_WINDOW')
      ENV.delete('RESEARCH_FORWARD_WINDOW')
      ENV.delete('RESEARCH_STABLE_REGION_MIN_TRADES')
      ENV.delete('RESEARCH_STABLE_REGION_MIN_PF')
      ENV.delete('RESEARCH_WALK_FORWARD_STEP')
      ENV.delete('CUSTOM_DEFAULT_LOOKBACK')
      ENV.delete('CUSTOM_OPTIMIZATION_WINDOW')
      ENV.delete('CUSTOM_FORWARD_WINDOW')
      ENV.delete('CUSTOM_STABLE_REGION_MIN_TRADES')
      ENV.delete('CUSTOM_STABLE_REGION_MIN_PF')
      ENV.delete('CUSTOM_WALK_FORWARD_STEP')

      example.run

      # Restore or clean up
      original_env.each { |k, v| ENV[k] = v }
    end

    it 'reads from ENV with default prefix RESEARCH' do
      ENV['RESEARCH_DEFAULT_LOOKBACK'] = '600'
      ENV['RESEARCH_OPTIMIZATION_WINDOW'] = '400'
      ENV['RESEARCH_FORWARD_WINDOW'] = '100'
      ENV['RESEARCH_STABLE_REGION_MIN_TRADES'] = '30'
      ENV['RESEARCH_STABLE_REGION_MIN_PF'] = '1.8'
      ENV['RESEARCH_WALK_FORWARD_STEP'] = '50'

      instance = described_class.from_env

      expect(instance.default_lookback).to eq(600)
      expect(instance.optimization_window).to eq(400)
      expect(instance.forward_window).to eq(100)
      expect(instance.stable_region_min_trades).to eq(30)
      expect(instance.stable_region_min_pf).to be_within(0.01).of(1.8)
      expect(instance.walk_forward_step).to eq(50)
    end

    it 'falls back to DEFAULTS when env var is missing' do
      # No env vars set
      instance = described_class.from_env

      expect(instance.default_lookback).to eq(500)
      expect(instance.optimization_window).to eq(500)
      expect(instance.forward_window).to eq(100)
      expect(instance.stable_region_min_trades).to eq(20)
      expect(instance.stable_region_min_pf).to eq(1.0)
      expect(instance.walk_forward_step).to eq(100)
    end

    it 'falls back to DEFAULTS for individual missing env vars' do
      ENV['RESEARCH_DEFAULT_LOOKBACK'] = '700'
      # Other vars are missing, should use DEFAULTS

      instance = described_class.from_env

      expect(instance.default_lookback).to eq(700)
      expect(instance.optimization_window).to eq(500)
      expect(instance.forward_window).to eq(100)
      expect(instance.stable_region_min_trades).to eq(20)
      expect(instance.stable_region_min_pf).to eq(1.0)
      expect(instance.walk_forward_step).to eq(100)
    end

    it 'works with explicit custom prefix' do
      ENV['CUSTOM_DEFAULT_LOOKBACK'] = '800'
      ENV['CUSTOM_OPTIMIZATION_WINDOW'] = '600'
      ENV['CUSTOM_FORWARD_WINDOW'] = '150'
      ENV['CUSTOM_STABLE_REGION_MIN_TRADES'] = '25'
      ENV['CUSTOM_STABLE_REGION_MIN_PF'] = '2.0'
      ENV['CUSTOM_WALK_FORWARD_STEP'] = '75'

      instance = described_class.from_env('CUSTOM')

      expect(instance.default_lookback).to eq(800)
      expect(instance.optimization_window).to eq(600)
      expect(instance.forward_window).to eq(150)
      expect(instance.stable_region_min_trades).to eq(25)
      expect(instance.stable_region_min_pf).to eq(2.0)
      expect(instance.walk_forward_step).to eq(75)
    end

    it 'returns frozen instance from from_env' do
      ENV['RESEARCH_DEFAULT_LOOKBACK'] = '600'

      instance = described_class.from_env

      expect(instance).to be_frozen
    end

    it 'accepts a block for post-processing' do
      ENV['RESEARCH_DEFAULT_LOOKBACK'] = '600'

      instance = described_class.from_env do |settings|
        # Block is called after initialization
      end

      expect(instance.default_lookback).to eq(600)
    end
  end
end