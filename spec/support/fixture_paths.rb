# frozen_string_literal: true

require "pathname"

module FixturePaths
  module_function

  BINANCE_ROOT =
    Rails.root.join(
      "spec",
      "fixtures",
      "binance"
    )

  SNAPSHOTS_ROOT =
    Rails.root.join(
      "spec",
      "fixtures",
      "snapshots"
    )

  def binance(name)
    validate_relative_path!(name)

    BINANCE_ROOT
      .join(name)
      .cleanpath
      .to_s
  end

  def snapshot(name)
    validate_relative_path!(name)

    SNAPSHOTS_ROOT
      .join(name)
      .cleanpath
      .to_s
  end

  def validate_relative_path!(name)
    unless name.is_a?(String) && !name.strip.empty?
      raise ArgumentError,
            "fixture name cannot be blank"
    end

    path = Pathname.new(name)

    if path.absolute?
      raise ArgumentError,
            "absolute paths are not allowed"
    end

    if name.include?("..")
      raise ArgumentError,
            "path traversal detected"
    end

    true
  end
end
