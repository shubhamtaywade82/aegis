# frozen_string_literal: true

require_relative 'settings'

class ResearchSettings < Settings
  integer :default_lookback
  integer :optimization_window
  integer :forward_window
  integer :stable_region_min_trades
  float   :stable_region_min_pf
  integer :walk_forward_step

  DEFAULTS = {
    default_lookback:          500,
    optimization_window:       500,
    forward_window:            100,
    stable_region_min_trades:  20,
    stable_region_min_pf:      1.0,
    walk_forward_step:         100
  }.freeze

  class << self
    def from_env(prefix = 'RESEARCH', &block)
      attrs = {}

      required_fields.each do |name, type|
        env_key = "#{prefix}_#{name}".upcase
        raw     = ENV.fetch(env_key, nil)

        attrs[name] = if raw.nil? || raw == ''
                        cast_with_default(type, name)
                      else
                        cast(type, raw)
                      end
      end

      instance = new(**attrs)
      block.call(instance) if block
      instance
    end

    private

    def cast_with_default(type, name)
      default = DEFAULTS.fetch(name) do
        raise ArgumentError, "No default defined for #{name}"
      end
      cast(type, default)
    end
  end

  def validate!
    validate_positive(:default_lookback, 'Default lookback')
    validate_positive(:optimization_window, 'Optimization window')
    validate_positive(:forward_window, 'Forward window')
    validate_positive(:stable_region_min_trades, 'Stable region min trades')
    validate_positive_float(:stable_region_min_pf, 'Stable region min profit factor')
    validate_positive(:walk_forward_step, 'Walk forward step')

    unless optimization_window >= forward_window
      raise ConfigurationError.new(
        "optimization_window (#{optimization_window}) must be >= forward_window (#{forward_window})",
        code: 'RESEARCH_WINDOW_INVALID',
        details: { optimization_window: optimization_window, forward_window: forward_window }
      )
    end
  end

  private

  def validate_positive(field, label = nil)
    label ||= field.to_s.tr('_', ' ')
    value = public_send(field)
    return if value.to_i > 0

    raise ConfigurationError.new(
      "#{label} must be a positive integer, got: #{value.inspect}",
      code: "RESEARCH_#{field.to_s.upcase}_INVALID",
      details: { field => value }
    )
  end

  def validate_positive_float(field, label = nil)
    label ||= field.to_s.tr('_', ' ')
    value = public_send(field)
    return if value.to_f > 0.0

    raise ConfigurationError.new(
      "#{label} must be a positive number, got: #{value.inspect}",
      code: "RESEARCH_#{field.to_s.upcase}_INVALID",
      details: { field => value }
    )
  end
end
