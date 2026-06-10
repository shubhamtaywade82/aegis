# frozen_string_literal: true

require_relative '../errors/configuration_error'

module Settings
  class Research
    class << self
      def optimization_bars
        Integer(ENV.fetch('RESEARCH_OPTIMIZATION_BARS'))
      end

      def forward_bars
        Integer(ENV.fetch('RESEARCH_FORWARD_BARS'))
      end

      def minimum_trades
        Integer(ENV.fetch('RESEARCH_MINIMUM_TRADES'))
      end

      def atr_stop_multiplier
        Float(ENV.fetch('RESEARCH_ATR_STOP_MULTIPLIER'))
      end

      def reward_risk_ratio
        Float(ENV.fetch('RESEARCH_REWARD_RISK_RATIO'))
      end

      def validate!
        errors = []

        errors << 'optimization_bars must be greater than forward_bars' unless optimization_bars > forward_bars
        errors << 'minimum_trades must be at least 1' unless minimum_trades >= 1
        errors << 'atr_stop_multiplier must be greater than 0.0' unless atr_stop_multiplier > 0.0
        errors << 'reward_risk_ratio must be greater than 0.0' unless reward_risk_ratio > 0.0

        raise ConfigurationError, errors.join('; ') unless errors.empty?
      end
    end
  end
end