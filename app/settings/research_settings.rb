# frozen_string_literal: true

module ResearchSettings
  DEFAULT_OPTIMIZATION_BARS = 500
  DEFAULT_FORWARD_BARS      = 100
  DEFAULT_MINIMUM_TRADES    = 20

  DEFAULT_ATR_MULTIPLIER    = 1.0
  DEFAULT_REWARD_RISK       = 2.0

  module_function

  def optimization_bars
    Settings.integer(
      "OPTIMIZATION_BARS",
      DEFAULT_OPTIMIZATION_BARS
    )
  end

  def forward_bars
    Settings.integer(
      "FORWARD_BARS",
      DEFAULT_FORWARD_BARS
    )
  end

  def minimum_trades
    Settings.integer(
      "MINIMUM_TRADES",
      DEFAULT_MINIMUM_TRADES
    )
  end

  def atr_stop_multiplier
    Settings.float(
      "ATR_STOP_MULTIPLIER",
      DEFAULT_ATR_MULTIPLIER
    )
  end

  def reward_risk_ratio
    Settings.float(
      "REWARD_RISK_RATIO",
      DEFAULT_REWARD_RISK
    )
  end

  def validate!
    validate_windows!
    validate_minimum_trades!
    validate_risk!

    true
  end

  def validate_windows!
    return if optimization_bars > forward_bars

    raise ConfigurationError,
          "OPTIMIZATION_BARS must be greater than FORWARD_BARS"
  end

  def validate_minimum_trades!
    return if minimum_trades.positive?

    raise ConfigurationError,
          "MINIMUM_TRADES must be greater than zero"
  end

  def validate_risk!
    unless atr_stop_multiplier.positive?
      raise ConfigurationError,
            "ATR_STOP_MULTIPLIER must be greater than zero"
    end

    return if reward_risk_ratio.positive?

    raise ConfigurationError,
          "REWARD_RISK_RATIO must be greater than zero"
  end
end
