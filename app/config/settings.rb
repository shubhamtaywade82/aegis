# frozen_string_literal: true

require_relative '../errors/configuration_error'

class Settings
  class << self
    # Loads configuration from environment variables.
    #
    # @param prefix [String, nil] Optional env var prefix (e.g. "BINANCE" → "BINANCE_API_KEY")
    # @param block [Proc] Optional DSL block yielded with self for subclass configuration
    # @return [subclass instance] Fully initialized, frozen settings object
    def from_env(prefix = nil, &block)
      attrs = {}

      all_fields.each do |name, type|
        env_key = build_env_key(prefix, name)
        value   = ENV.fetch(env_key) { nil }

        attrs[name] = cast(type, value)
      end

      instance = new(**attrs)
      block.call(instance) if block
      instance
    end

    def required(name, type: :string)
      required_fields[name] = type
      attr_reader name
      define_writer(name, type)
    end

    def boolean(name)
      required(name, type: :boolean)
    end

    def integer(name)
      required(name, type: :integer)
    end

    def string(name)
      required(name, type: :string)
    end

    def optional(name, type: :string)
      optional_fields[name] = type
      attr_reader name
      define_writer(name, type)
    end

    def optional_boolean(name)
      optional(name, type: :boolean)
    end

    def optional_integer(name)
      optional(name, type: :integer)
    end

    def float(name)
      required(name, type: :float)
    end

    def optional_float(name)
      optional(name, type: :float)
    end

    def cast(type, value)
      return nil if value.nil? || value == ''

      case type
      when :string   then value.to_s
      when :integer  then cast_integer(value)
      when :boolean  then cast_boolean(value)
      when :float    then cast_float(value)
      else                value
      end
    end

    private

    def required_fields
      @required_fields ||= {}
    end

    def optional_fields
      @optional_fields ||= {}
    end

    def all_fields
      required_fields.merge(optional_fields)
    end

    def build_env_key(prefix, name)
      prefix ? "#{prefix}_#{name}".upcase : name.upcase
    end

    def define_writer(name, type)
      define_method(:"#{name}=") do |value|
        normalized = value.is_a?(String) ? value.strip : value
        instance_variable_set(:"@#{name}", self.class.cast(type, normalized))
      end
    end

    def cast_integer(value)
      return value if value.is_a?(Integer)
      int = Integer(value)
      raise ArgumentError, "non-integer value: #{value.inspect}" unless value.to_s =~ /\A-?\d+\z/
      int
    rescue ArgumentError
      raise ConfigurationError, "Invalid integer value: #{value.inspect}"
    end

    def cast_float(value)
      return value if value.is_a?(Float)
      Float(value)
    rescue ArgumentError
      raise ConfigurationError, "Invalid float value: #{value.inspect}"
    end

    def cast_boolean(value)
      case value
      when true, 'true', '1', 'yes' then true
      when false, 'false', '0', 'no' then false
      when nil, '' then false
      else
        raise ConfigurationError, "Invalid boolean value: #{value.inspect}"
      end
    end
  end

  # @param attrs [Hash] attribute values (symbol keys), overrides env-derived values
  def initialize(attrs = {})
    attrs.each do |name, value|
      public_send(:"#{name}=", value)
    end
    validate!
    freeze
  end

  # Override in subclass to perform validation.
  # Raises ConfigurationError on failure.
  def validate!
    # Subclasses should override; base implementation is a no-op.
    raise NotImplementedError, "#{self.class} must implement #validate!"
  end

  # Returns all configured values as a hash with symbol keys.
  # Only includes attributes defined via the DSL macros.
  def to_h
    result = {}
    instance_variables.each do |iv|
      name = iv.name[1..].to_sym  # strip leading @
      result[name] = instance_variable_get(iv)
    end
    result
  end
end