# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/errors/application_error'
require_relative '../../app/errors/configuration_error'
require_relative '../../app/errors/external_service_error'
require_relative '../../app/errors/binance_error'
require_relative '../../app/errors/rate_limit_error'
require_relative '../../app/errors/validation_error'
require_relative '../../app/errors/research_error'
require_relative '../../app/errors/execution_error'

RSpec.describe 'Error Hierarchy' do
  describe ApplicationError do
    it 'inherits from StandardError' do
      expect(ApplicationError.superclass).to eq(StandardError)
    end

    it 'can be raised and caught' do
      expect { raise ApplicationError, 'test' }.to raise_error(ApplicationError)
    end
  end

  describe ConfigurationError do
    it 'inherits from ApplicationError' do
      expect(ConfigurationError.superclass).to eq(ApplicationError)
    end

    it 'can be raised and caught as ApplicationError' do
      expect { raise ConfigurationError, 'config issue' }.to raise_error(ApplicationError)
    end
  end

  describe ExternalServiceError do
    it 'inherits from ApplicationError' do
      expect(ExternalServiceError.superclass).to eq(ApplicationError)
    end

    it 'can be raised and caught as ApplicationError' do
      expect { raise ExternalServiceError, 'service down' }.to raise_error(ApplicationError)
    end
  end

  describe BinanceError do
    it 'inherits from ExternalServiceError' do
      expect(BinanceError.superclass).to eq(ExternalServiceError)
    end

    it 'can be raised and caught as ExternalServiceError' do
      expect { raise BinanceError, 'binance issue' }.to raise_error(ExternalServiceError)
    end
  end

  describe RateLimitError do
    it 'inherits from BinanceError' do
      expect(RateLimitError.superclass).to eq(BinanceError)
    end

    it 'can be raised and caught as BinanceError' do
      expect { raise RateLimitError, 'rate limited' }.to raise_error(BinanceError)
    end
  end

  describe ValidationError do
    it 'inherits from ApplicationError' do
      expect(ValidationError.superclass).to eq(ApplicationError)
    end

    it 'can be raised and caught as ApplicationError' do
      expect { raise ValidationError, 'invalid' }.to raise_error(ApplicationError)
    end
  end

  describe ResearchError do
    it 'inherits from ApplicationError' do
      expect(ResearchError.superclass).to eq(ApplicationError)
    end

    it 'can be raised and caught as ApplicationError' do
      expect { raise ResearchError, 'research failed' }.to raise_error(ApplicationError)
    end
  end

  describe ExecutionError do
    it 'inherits from ApplicationError' do
      expect(ExecutionError.superclass).to eq(ApplicationError)
    end

    it 'can be raised and caught as ApplicationError' do
      expect { raise ExecutionError, 'execution failed' }.to raise_error(ApplicationError)
    end
  end
end