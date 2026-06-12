# frozen_string_literal: true

require "rails_helper"

RSpec.describe Strategy::PositionTracker do
  let(:redis) { MarketDataFeed.redis }

  subject(:tracker) { described_class.new(redis: redis) }

  before do
    redis.flushdb
  end

  after do
    redis.flushdb
  end

  describe "#current_position" do
    it "returns nil when no position exists" do
      result = tracker.current_position("BTCUSDT")
      expect(result).to be_nil
    end

    it "returns nil when hash exists but has no fields" do
      redis.del("strategy:position:EMPTY")
      redis.hset("strategy:position:EMPTY", "some_field", "value")
      tracker.clear_position("EMPTY")

      result = tracker.current_position("EMPTY")
      expect(result).to be_nil
    end

    it "handles missing individual hash fields gracefully" do
      key = "strategy:position:PARTIAL"
      redis.hset(key, "side", "long")
      # quantity and entry_price are missing

      result = tracker.current_position("PARTIAL")
      expect(result).to be_nil
    end

    it "returns nil when side is missing" do
      key = "strategy:position:NOSIDE"
      redis.hset(key, "quantity", "1.5", "entry_price", "50000.00")

      result = tracker.current_position("NOSIDE")
      expect(result).to be_nil
    end

    it "returns nil when quantity is missing" do
      key = "strategy:position:NOQUANTITY"
      redis.hset(key, "side", "long", "entry_price", "50000.00")

      result = tracker.current_position("NOQUANTITY")
      expect(result).to be_nil
    end

    it "returns nil when entry_price is missing" do
      key = "strategy:position:NOENTRYPRICE"
      redis.hset(key, "side", "long", "quantity", "1.5")

      result = tracker.current_position("NOENTRYPRICE")
      expect(result).to be_nil
    end
  end

  describe "#set_position" do
    it "stores position data in Redis hash" do
      tracker.set_position("BTCUSDT", side: :long, quantity: BigDecimal("1.5"), entry_price: BigDecimal("50000.00"))

      key = "strategy:position:BTCUSDT"
      expect(redis.hexists(key, "side")).to be true
      expect(redis.hexists(key, "quantity")).to be true
      expect(redis.hexists(key, "entry_price")).to be true
    end

    it "stores side as lowercase string" do
      tracker.set_position("ETHUSDT", side: :LONG, quantity: "2.0", entry_price: "3000.00")

      stored_side = redis.hget("strategy:position:ETHUSDT", "side")
      expect(stored_side).to eq("long")
    end

    it "stores quantity as string" do
      tracker.set_position("SOLUSDT", side: :short, quantity: BigDecimal("10.5"), entry_price: "150.00")

      stored_quantity = redis.hget("strategy:position:SOLUSDT", "quantity")
      expect(stored_quantity).to eq("10.5")
    end

    it "stores entry_price as string" do
      tracker.set_position("BNBUSDT", side: :long, quantity: "5.0", entry_price: BigDecimal("600.25"))

      stored_price = redis.hget("strategy:position:BNBUSDT", "entry_price")
      expect(stored_price).to eq("600.25")
    end

    it "handles different symbols independently" do
      tracker.set_position("BTCUSDT", side: :long, quantity: "1.0", entry_price: "50000.00")
      tracker.set_position("ETHUSDT", side: :short, quantity: "2.0", entry_price: "3000.00")

      btc_position = redis.hgetall("strategy:position:BTCUSDT")
      eth_position = redis.hgetall("strategy:position:ETHUSDT")

      expect(btc_position["side"]).to eq("long")
      expect(eth_position["side"]).to eq("short")
      expect(btc_position["quantity"]).to eq("1.0")
      expect(eth_position["quantity"]).to eq("2.0")
    end
  end

  describe "#current_position after #set_position" do
    it "returns parsed hash with BigDecimal values after set" do
      tracker.set_position("BTCUSDT", side: :long, quantity: BigDecimal("1.5"), entry_price: BigDecimal("50000.00"))

      result = tracker.current_position("BTCUSDT")

      expect(result).to be_a(Hash)
      expect(result[:side]).to eq(:long)
      expect(result[:quantity]).to be_a(BigDecimal)
      expect(result[:quantity]).to eq(BigDecimal("1.5"))
      expect(result[:entry_price]).to be_a(BigDecimal)
      expect(result[:entry_price]).to eq(BigDecimal("50000.00"))
    end

    it "side is normalized and returned as symbol (:long or :short)" do
      tracker.set_position("ETHUSDT", side: "LONG", quantity: "1.0", entry_price: "3000.00")
      result = tracker.current_position("ETHUSDT")
      expect(result[:side]).to eq(:long)

      tracker.set_position("SOLUSDT", side: "SHORT", quantity: "5.0", entry_price: "150.00")
      result = tracker.current_position("SOLUSDT")
      expect(result[:side]).to eq(:short)

      tracker.set_position("BNBUSDT", side: :Long, quantity: "2.0", entry_price: "600.00")
      result = tracker.current_position("BNBUSDT")
      expect(result[:side]).to eq(:long)

      tracker.set_position("XRPUSDT", side: :Short, quantity: "10.0", entry_price: "2.50")
      result = tracker.current_position("XRPUSDT")
      expect(result[:side]).to eq(:short)
    end
  end

  describe "#clear_position" do
    it "removes the position from Redis" do
      tracker.set_position("BTCUSDT", side: :long, quantity: "1.0", entry_price: "50000.00")

      expect(redis.exists("strategy:position:BTCUSDT")).to eq(1)

      tracker.clear_position("BTCUSDT")

      expect(redis.exists("strategy:position:BTCUSDT")).to eq(0)
    end

    it "returns nil after clear" do
      tracker.set_position("BTCUSDT", side: :long, quantity: "1.0", entry_price: "50000.00")
      tracker.clear_position("BTCUSDT")

      result = tracker.current_position("BTCUSDT")
      expect(result).to be_nil
    end

    it "handles clearing non-existent position gracefully" do
      expect {
        tracker.clear_position("NONEXISTENT")
      }.not_to raise_error
    end
  end

  describe "integration: full lifecycle" do
    it "tracks complete position lifecycle" do
      # Initially no position
      expect(tracker.current_position("BTCUSDT")).to be_nil

      # Open a long position
      tracker.set_position("BTCUSDT", side: :long, quantity: "1.5", entry_price: "50000.00")
      position = tracker.current_position("BTCUSDT")
      expect(position[:side]).to eq(:long)
      expect(position[:quantity]).to eq(BigDecimal("1.5"))
      expect(position[:entry_price]).to eq(BigDecimal("50000.00"))

      # Close the position
      tracker.clear_position("BTCUSDT")
      expect(tracker.current_position("BTCUSDT")).to be_nil

      # Open a short position
      tracker.set_position("BTCUSDT", side: :short, quantity: "0.5", entry_price: "51000.00")
      position = tracker.current_position("BTCUSDT")
      expect(position[:side]).to eq(:short)
      expect(position[:quantity]).to eq(BigDecimal("0.5"))
      expect(position[:entry_price]).to eq(BigDecimal("51000.00"))
    end
  end
end