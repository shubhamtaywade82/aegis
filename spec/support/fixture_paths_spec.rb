# frozen_string_literal: true

require "rails_helper"
require_relative "fixture_paths"


RSpec.describe FixturePaths do
  describe ".binance" do
    it "builds the binance fixture path" do
      path =
        described_class.binance(
          "SOLUSDT_1h_2025_01.json"
        )

      expect(path).to include(
        "spec/fixtures/binance"
      )

      expect(path).to end_with(
        "SOLUSDT_1h_2025_01.json"
      )
    end

    it "returns an absolute path" do
      path =
        described_class.binance(
          "SOLUSDT_1h_2025_01.json"
        )

      expect(Pathname.new(path))
        .to be_absolute
    end

    it "supports nested fixture names" do
      path =
        described_class.binance(
          "archive/SOLUSDT_1h_2025_01.json"
        )

      expect(path).to end_with(
        "archive/SOLUSDT_1h_2025_01.json"
      )
    end

    it "does not modify the fixture name" do
      fixture_name =
        "SOLUSDT_1h_2025_01.json"

      path =
        described_class.binance(
          fixture_name
        )

      expect(
        File.basename(path)
      ).to eq(fixture_name)
    end
  end

  describe ".snapshot" do
    it "builds snapshot paths" do
      path =
        described_class.snapshot(
          "solusdt_1h_st_10_3.yml"
        )

      expect(path).to include(
        "spec/fixtures/snapshots"
      )

      expect(path).to end_with(
        "solusdt_1h_st_10_3.yml"
      )
    end

    it "returns an absolute path" do
      path =
        described_class.snapshot(
          "snapshot.yml"
        )

      expect(Pathname.new(path))
        .to be_absolute
    end

    it "supports nested snapshot directories" do
      path =
        described_class.snapshot(
          "optimizer/solusdt.yml"
        )

      expect(path).to end_with(
        "optimizer/solusdt.yml"
      )
    end

    it "does not modify snapshot names" do
      snapshot_name =
        "walk_forward/btcusdt.yml"

      path =
        described_class.snapshot(
          snapshot_name
        )

      expect(
        path.end_with?(snapshot_name)
      ).to be(true)
    end
  end

  describe "root consistency" do
    it "uses Rails.root for binance fixtures" do
      path =
        described_class.binance(
          "fixture.json"
        )

      expect(path).to start_with(
        Rails.root.to_s
      )
    end

    it "uses Rails.root for snapshots" do
      path =
        described_class.snapshot(
          "snapshot.yml"
        )

      expect(path).to start_with(
        Rails.root.to_s
      )
    end
  end

  describe "determinism" do
    it "returns identical paths for identical inputs" do
      first =
        described_class.binance(
          "SOLUSDT_1h_2025_01.json"
        )

      second =
        described_class.binance(
          "SOLUSDT_1h_2025_01.json"
        )

      expect(first).to eq(second)
    end

    it "returns identical snapshot paths for identical inputs" do
      first =
        described_class.snapshot(
          "sol_snapshot.yml"
        )

      second =
        described_class.snapshot(
          "sol_snapshot.yml"
        )

      expect(first).to eq(second)
    end
  end

  describe "path validation" do
    it "rejects blank fixture names" do
      expect do
        described_class.binance("")
      end.to raise_error(
        ArgumentError,
        "fixture name cannot be blank"
      )
    end

    it "rejects nil fixture names" do
      expect do
        described_class.snapshot(nil)
      end.to raise_error(
        ArgumentError,
        "fixture name cannot be blank"
      )
    end

    it "rejects absolute paths" do
      expect do
        described_class.binance(
          "/etc/passwd"
        )
      end.to raise_error(
        ArgumentError,
        "absolute paths are not allowed"
      )
    end

    it "rejects path traversal in binance paths" do
      expect do
        described_class.binance(
          "../../config/database.yml"
        )
      end.to raise_error(
        ArgumentError,
        "path traversal detected"
      )
    end

    it "rejects path traversal in snapshot paths" do
      expect do
        described_class.snapshot(
          "../snapshots.yml"
        )
      end.to raise_error(
        ArgumentError,
        "path traversal detected"
      )
    end
  end
end
