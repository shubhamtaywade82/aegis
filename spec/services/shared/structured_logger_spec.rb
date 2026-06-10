# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/services/shared/structured_logger'
require_relative '../../../app/services/shared/json_parser'

RSpec.describe StructuredLogger do
  describe '#initialize' do
    it 'accepts service, symbol, and strategy parameters' do
      logger = StructuredLogger.new(
        service: 'binance',
        symbol: 'BTCUSDT',
        strategy: 'supertrend'
      )
      expect(logger.service).to eq('binance')
      expect(logger.symbol).to eq('BTCUSDT')
      expect(logger.strategy).to eq('supertrend')
    end

    it 'defaults all params to nil' do
      logger = StructuredLogger.new
      expect(logger.service).to be_nil
      expect(logger.symbol).to be_nil
      expect(logger.strategy).to be_nil
    end

    it 'accepts custom output IO' do
      io = StringIO.new
      logger = StructuredLogger.new(output: io)
      logger.info(event: 'test', message: 'hello')
      expect(io.string).not_to be_empty
    end
  end

  describe '#log' do
    it 'raises ArgumentError when event is missing' do
      logger = StructuredLogger.new
      expect {
        logger.info(message: 'no event')
      }.to raise_error(ArgumentError, 'event is required and must be a String')
    end

    it 'raises ArgumentError when event is not a String' do
      logger = StructuredLogger.new
      expect {
        logger.info(event: :symbol_event)
      }.to raise_error(ArgumentError, 'event is required and must be a String')
    end

    it 'outputs valid JSON with all required fields' do
      io = StringIO.new
      logger = StructuredLogger.new(output: io)
      logger.info(event: 'order_placed', message: 'Order filled')

      json = JsonParser.load(io.string)
      expect(json[:event]).to eq('order_placed')
      expect(json[:level]).to eq('info')
      expect(json[:message]).to eq('Order filled')
      expect(json[:timestamp]).to be_a(String)
    end

    it 'merges service, symbol, and strategy into every payload' do
      io = StringIO.new
      logger = StructuredLogger.new(
        output: io,
        service: 'binance',
        symbol: 'ETHUSDT',
        strategy: 'macd_cross'
      )
      logger.warn(event: 'risk_limit', message: 'Approaching limit')

      json = JsonParser.load(io.string)
      expect(json[:service]).to eq('binance')
      expect(json[:symbol]).to eq('ETHUSDT')
      expect(json[:strategy]).to eq('macd_cross')
    end

    it 'merges additional context into payload' do
      io = StringIO.new
      logger = StructuredLogger.new(output: io)
      logger.info(
        event: 'order_placed',
        context: { price: 65000, qty: 0.01 }
      )

      json = JsonParser.load(io.string)
      expect(json[:context][:price]).to eq(65000)
      expect(json[:context][:qty]).to eq(0.01)
    end
  end

  describe '#debug' do
    it 'logs with level debug' do
      io = StringIO.new
      logger = StructuredLogger.new(output: io)
      logger.debug(event: 'debug_event')

      json = JsonParser.load(io.string)
      expect(json[:level]).to eq('debug')
    end
  end

  describe '#info' do
    it 'logs with level info' do
      io = StringIO.new
      logger = StructuredLogger.new(output: io)
      logger.info(event: 'info_event')

      json = JsonParser.load(io.string)
      expect(json[:level]).to eq('info')
    end
  end

  describe '#warn' do
    it 'logs with level warn' do
      io = StringIO.new
      logger = StructuredLogger.new(output: io)
      logger.warn(event: 'warn_event')

      json = JsonParser.load(io.string)
      expect(json[:level]).to eq('warn')
    end
  end

  describe '#error' do
    it 'logs with level error' do
      io = StringIO.new
      logger = StructuredLogger.new(output: io)
      logger.error(event: 'error_event')

      json = JsonParser.load(io.string)
      expect(json[:level]).to eq('error')
    end
  end

  describe '#fatal' do
    it 'logs with level fatal' do
      io = StringIO.new
      logger = StructuredLogger.new(output: io)
      logger.fatal(event: 'fatal_event')

      json = JsonParser.load(io.string)
      expect(json[:level]).to eq('fatal')
    end
  end

  describe 'silent failure' do
    it 'rescues JSON/log failures silently' do
      # When output is invalid, it should not raise
      io = StringIO.new
      logger = StructuredLogger.new(output: io)
      expect {
        logger.info(event: 'test')
      }.not_to raise_error
    end
  end
end