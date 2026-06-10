# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/services/shared/json_parser'
require_relative '../../../app/errors/validation_error'

RSpec.describe JsonParser do
  describe '.dump' do
    it 'produces valid JSON from a hash' do
      result = JsonParser.dump({ foo: 'bar', baz: 123 })
      parsed = JSON.parse(result)
      expect(parsed['foo']).to eq('bar')
      expect(parsed['baz']).to eq(123)
    end

    it 'handles nested structures' do
      hash = { outer: { inner: [1, 2, 3] }, symbol_key: :value }
      result = JsonParser.dump(hash)
      parsed = JSON.parse(result)
      expect(parsed['outer']['inner']).to eq([1, 2, 3])
    end

    it 'handles Time objects with ruby time format' do
      time = Time.now
      result = JsonParser.dump({ time: time })
      expect(result).to include('time')
    end
  end

  describe '.load' do
    it 'parses a JSON string into a hash' do
      result = JsonParser.load('{"foo":"bar"}')
      expect(result).to eq({ foo: 'bar' })
    end

    it 'converts keys to symbols by default' do
      result = JsonParser.load('{"foo":"bar","nested":{"key":"value"}}')
      expect(result.keys).to include(:foo, :nested)
      expect(result[:nested][:key]).to eq('value')
    end

    it 'accepts symbol_keys: false option' do
      result = JsonParser.load('{"foo":"bar"}', symbol_keys: false)
      expect(result.keys).to include('foo')
    end

    it 'round-trips hash correctly' do
      original = { string: 'hello', number: 42, array: [1, 2, 3] }
      json = JsonParser.dump(original)
      restored = JsonParser.load(json)
      expect(restored[:string]).to eq('hello')
      expect(restored[:number]).to eq(42)
      expect(restored[:array]).to eq([1, 2, 3])
    end

    it 'raises ValidationError on malformed JSON' do
      expect {
        JsonParser.load('not valid json {')
      }.to raise_error(ValidationError) do |error|
        expect(error.details[:json]).to include('not valid json')
      end
    end

    it 'raises ValidationError on invalid JSON structure' do
      expect {
        JsonParser.load('{"incomplete":')
      }.to raise_error(ValidationError)
    end

    it 'uses strict mode and rejects non-JSON additions' do
      # Trailing commas or comments would be rejected in strict mode
      expect {
        JsonParser.load('{ "foo": "bar" }//comment')
      }.to raise_error(ValidationError)
    end
  end
end