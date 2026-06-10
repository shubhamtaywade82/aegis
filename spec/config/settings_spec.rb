# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/config/settings'
require_relative '../../app/config/binance_settings'
require_relative '../../app/config/research_settings'
require_relative '../../app/errors/configuration_error'

RSpec.describe Settings do
  describe 'DSL macros' do
    context 'with required fields' do
      before do
        stub_class = Class.new(Settings) do
          required :name, type: :string
          required :count, type: :integer
          required :enabled, type: :boolean
          required :ratio, type: :float

          def validate!
            # no-op for testing
          end
        end
        stub_const('TestRequiredSettings', stub_class)
      end

      it 'defines attr_reader for each required field' do
        instance = TestRequiredSettings.new(name: 'test', count: 1, enabled: true, ratio: 1.5)
        expect(instance.name).to eq('test')
        expect(instance.count).to eq(1)
        expect(instance.enabled).to eq(true)
        expect(instance.ratio).to eq(1.5)
      end

      it 'defines writer that casts string values' do
        instance = TestRequiredSettings.new(
          name: '  hello  ',
          count: '42',
          enabled: 'true',
          ratio: '3.14'
        )

        expect(instance.name).to eq('hello')
        expect(instance.count).to eq(42)
        expect(instance.enabled).to eq(true)
        expect(instance.ratio).to eq(3.14)
      end
    end

    context 'with optional fields' do
      before do
        stub_class = Class.new(Settings) do
          optional :nickname, type: :string
          optional :quantity, type: :integer
          optional :active, type: :boolean
          optional :threshold, type: :float

          def validate!
            # no-op for testing
          end
        end
        stub_const('TestOptionalSettings', stub_class)
      end

      it 'defines attr_reader for each optional field' do
        instance = TestOptionalSettings.new(
          nickname: 'test',
          quantity: 5,
          active: false,
          threshold: 2.5
        )
        expect(instance.nickname).to eq('test')
        expect(instance.quantity).to eq(5)
        expect(instance.active).to eq(false)
        expect(instance.threshold).to eq(2.5)
      end

      it 'optional fields default to nil when not provided' do
        instance = TestOptionalSettings.new
        expect(instance.nickname).to be_nil
        expect(instance.quantity).to be_nil
        expect(instance.active).to be_nil
        expect(instance.threshold).to be_nil
      end
    end

    context 'convenience macros' do
      before do
        stub_class = Class.new(Settings) do
          string       :full_name
          integer      :max_retries
          boolean      :debug_mode
          float        :tolerance
          optional      :alias, type: :string
          optional     :page_size, type: :integer
          optional     :verbose, type: :boolean
          optional     :epsilon, type: :float

          def validate!
            # no-op for testing
          end
        end
        stub_const('TestConvenienceSettings', stub_class)
      end

      it 'string creates a required string field' do
        instance = TestConvenienceSettings.new(full_name: 'Test')
        expect(instance.full_name).to eq('Test')
      end

      it 'integer creates a required integer field' do
        instance = TestConvenienceSettings.new(max_retries: 3)
        expect(instance.max_retries).to eq(3)
      end

      it 'boolean creates a required boolean field' do
        instance = TestConvenienceSettings.new(debug_mode: true)
        expect(instance.debug_mode).to eq(true)
      end

      it 'float creates a required float field' do
        instance = TestConvenienceSettings.new(tolerance: 0.001)
        expect(instance.tolerance).to eq(0.001)
      end

      it 'optional string field defaults to nil' do
        instance = TestConvenienceSettings.new
        expect(instance.alias).to be_nil
      end

      it 'optional integer field defaults to nil' do
        instance = TestConvenienceSettings.new
        expect(instance.page_size).to be_nil
      end

      it 'optional boolean field defaults to nil' do
        instance = TestConvenienceSettings.new
        expect(instance.verbose).to be_nil
      end

      it 'optional float field defaults to nil' do
        instance = TestConvenienceSettings.new
        expect(instance.epsilon).to be_nil
      end
    end
  end

  describe '.cast' do
    before do
      stub_class = Class.new(Settings) do
        def validate!
          # no-op
        end
      end
      stub_const('TestCastSettings', stub_class)
    end

    it 'returns nil for nil input' do
      expect(TestCastSettings.cast(:string, nil)).to be_nil
    end

    it 'returns nil for empty string input' do
      expect(TestCastSettings.cast(:string, '')).to be_nil
    end

    it 'casts :string type' do
      expect(TestCastSettings.cast(:string, 'hello')).to eq('hello')
    end

    it 'casts :integer type from string' do
      expect(TestCastSettings.cast(:integer, '42')).to eq(42)
    end

    it 'raises ConfigurationError for invalid integer string' do
      expect { TestCastSettings.cast(:integer, 'abc') }
        .to raise_error(ConfigurationError, /Invalid integer value/)
    end

    it 'casts :boolean type to true for truthy values' do
      expect(TestCastSettings.cast(:boolean, 'true')).to eq(true)
      expect(TestCastSettings.cast(:boolean, '1')).to eq(true)
      expect(TestCastSettings.cast(:boolean, 'yes')).to eq(true)
      expect(TestCastSettings.cast(:boolean, true)).to eq(true)
    end

    it 'casts :boolean type to false for falsy values' do
      expect(TestCastSettings.cast(:boolean, 'false')).to eq(false)
      expect(TestCastSettings.cast(:boolean, '0')).to eq(false)
      expect(TestCastSettings.cast(:boolean, 'no')).to eq(false)
      expect(TestCastSettings.cast(:boolean, false)).to eq(false)
    end

    it 'raises ConfigurationError for invalid boolean value' do
      expect { TestCastSettings.cast(:boolean, 'maybe') }
        .to raise_error(ConfigurationError, /Invalid boolean value/)
    end

    it 'casts :float type from string' do
      expect(TestCastSettings.cast(:float, '3.14')).to be_within(0.001).of(3.14)
    end

    it 'raises ConfigurationError for invalid float string' do
      expect { TestCastSettings.cast(:float, 'not_a_float') }
        .to raise_error(ConfigurationError, /Invalid float value/)
    end

    it 'passes through non-string types when already correct' do
      expect(TestCastSettings.cast(:integer, 100)).to eq(100)
      expect(TestCastSettings.cast(:float, 2.5)).to eq(2.5)
    end
  end

  describe '#initialize' do
    it 'accepts symbol keys' do
      stub_class = Class.new(Settings) do
        string :name
        def validate!; end
      end
      stub_const('TestInitSettings', stub_class)

      instance = TestInitSettings.new(name: 'value')
      expect(instance.name).to eq('value')
    end

    it 'calls writers for each provided attribute' do
      stub_class = Class.new(Settings) do
        string :name
        integer :count
        def validate!; end
      end
      stub_const('TestWriterSettings', stub_class)

      instance = TestWriterSettings.new(name: 'test', count: '10')
      expect(instance.name).to eq('test')
      expect(instance.count).to eq(10)
    end

    it 'freezes the instance after initialization' do
      stub_class = Class.new(Settings) do
        string :name
        def validate!; end
      end
      stub_const('TestFrozenSettings', stub_class)

      instance = TestFrozenSettings.new(name: 'test')
      expect(instance).to be_frozen
    end

    it 'raises NotImplementedError when validate! is not overridden' do
      # Settings base class raises NotImplementedError when no fields defined
      # and validate! is called (which happens in initialize)
      expect { Settings.new }.to raise_error(NotImplementedError)
    end
  end

  describe '#to_h' do
    it 'returns a hash with symbol keys' do
      stub_class = Class.new(Settings) do
        string :name
        integer :count
        boolean :active
        def validate!; end
      end
      stub_const('TestToHashSettings', stub_class)

      instance = TestToHashSettings.new(name: 'test', count: 42, active: true)
      hash = instance.to_h

      expect(hash.keys).to include(:name, :count, :active)
      expect(hash[:name]).to eq('test')
      expect(hash[:count]).to eq(42)
      expect(hash[:active]).to eq(true)
    end

    it 'returns an empty hash when no fields are set' do
      stub_class = Class.new(Settings) do
        def validate!; end
      end
      stub_const('TestEmptyHashSettings', stub_class)

      instance = TestEmptyHashSettings.new
      expect(instance.to_h).to eq({})
    end
  end

  describe 'subclass without validate!' do
    it 'create a test subclass that does not break when missing validate!' do
      stub_class = Class.new(Settings) do
        string :name
        # no validate! override - inherits NotImplementedError
      end
      stub_const('TestNoValidateSettings', stub_class)

      # Direct instantiation should raise NotImplementedError
      expect { stub_class.new(name: 'test') }.to raise_error(NotImplementedError)
    end
  end
end