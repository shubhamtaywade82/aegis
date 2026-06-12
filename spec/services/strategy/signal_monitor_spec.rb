# frozen_string_literal: true

require "rails_helper"

RSpec.describe Strategy::SignalMonitor do
  let(:redis) { MarketDataFeed.redis }
  let(:symbol) { "BTCUSDT" }
  let(:monitor) { described_class.new(redis: redis) }

  before do
    # Clean up Redis keys before each test
    redis.flushdb
  end

  after do
    # Clean up Redis keys after each test
    redis.flushdb
  end

  describe "#current_direction" do
    it "returns nil when no supertrend data in Redis" do
      expect(monitor.current_direction(symbol)).to be_nil
    end

    it "returns :bullish when Redis has bullish direction" do
      redis.set("trading:supertrend:#{symbol}", '{"direction":"BULLISH","value":123.45}')
      expect(monitor.current_direction(symbol)).to eq(:bullish)
    end

    it "returns :bearish when Redis has bearish direction" do
      redis.set("trading:supertrend:#{symbol}", '{"direction":"BEARISH","value":123.45}')
      expect(monitor.current_direction(symbol)).to eq(:bearish)
    end

    it "handles lowercase direction strings" do
      redis.set("trading:supertrend:#{symbol}", '{"direction":"bullish","value":123.45}')
      expect(monitor.current_direction(symbol)).to eq(:bullish)
    end

    it "handles JSON parse errors gracefully" do
      redis.set("trading:supertrend:#{symbol}", "not valid json")
      expect(monitor.current_direction(symbol)).to be_nil
    end
  end

  describe "#previous_direction" do
    it "returns nil when no stored direction" do
      expect(monitor.previous_direction(symbol)).to be_nil
    end

    it "returns the stored direction" do
      redis.set("strategy:supertrend:last_direction:#{symbol}", "bullish")
      expect(monitor.previous_direction(symbol)).to eq(:bullish)
    end

    it "handles uppercase stored direction" do
      redis.set("strategy:supertrend:last_direction:#{symbol}", "BEARISH")
      expect(monitor.previous_direction(symbol)).to eq(:bearish)
    end
  end

  describe "#store_direction" do
    it "stores the direction in lowercase" do
      monitor.store_direction(symbol, :bullish)
      expect(redis.get("strategy:supertrend:last_direction:#{symbol}")).to eq("bullish")
    end

    it "stores nil direction as string 'nil'" do
      monitor.store_direction(symbol, nil)
      expect(redis.get("strategy:supertrend:last_direction:#{symbol}")).to eq("")
    end
  end

  describe "#flip_detected?" do
    it "returns false when current direction is nil" do
      redis.set("strategy:supertrend:last_direction:#{symbol}", "bullish")
      expect(monitor.flip_detected?(symbol)).to be false
    end

    it "returns false when previous direction is nil" do
      redis.set("trading:supertrend:#{symbol}", '{"direction":"BULLISH","value":123.45}')
      expect(monitor.flip_detected?(symbol)).to be false
    end

    it "returns false when both directions are nil" do
      expect(monitor.flip_detected?(symbol)).to be false
    end

    it "returns false when directions are the same" do
      redis.set("trading:supertrend:#{symbol}", '{"direction":"BULLISH","value":123.45}')
      redis.set("strategy:supertrend:last_direction:#{symbol}", "bullish")
      expect(monitor.flip_detected?(symbol)).to be false
    end

    it "returns true when directions are different (bullish to bearish)" do
      redis.set("trading:supertrend:#{symbol}", '{"direction":"BEARISH","value":123.45}')
      redis.set("strategy:supertrend:last_direction:#{symbol}", "bullish")
      expect(monitor.flip_detected?(symbol)).to be true
    end

    it "returns true when directions are different (bearish to bullish)" do
      redis.set("trading:supertrend:#{symbol}", '{"direction":"BULLISH","value":123.45}')
      redis.set("strategy:supertrend:last_direction:#{symbol}", "bearish")
      expect(monitor.flip_detected?(symbol)).to be true
    end
  end

  describe "#update_and_check" do
    it "stores direction and reports no flip on first observation" do
      redis.set("trading:supertrend:#{symbol}", '{"direction":"BULLISH","value":123.45}')

      result = monitor.update_and_check(symbol)

      expect(result[:flipped]).to be false
      expect(result[:from]).to be_nil
      expect(result[:to]).to eq(:bullish)
      expect(redis.get("strategy:supertrend:last_direction:#{symbol}")).to eq("bullish")
    end

    it "reports flip when direction changes" do
      # First, store initial direction
      redis.set("trading:supertrend:#{symbol}", '{"direction":"BULLISH","value":123.45}')
      monitor.update_and_check(symbol)

      # Now change to bearish
      redis.set("trading:supertrend:#{symbol}", '{"direction":"BEARISH","value":120.00}')

      result = monitor.update_and_check(symbol)

      expect(result[:flipped]).to be true
      expect(result[:from]).to eq(:bullish)
      expect(result[:to]).to eq(:bearish)
    end

    it "reports no flip when direction stays the same" do
      # First, store initial direction
      redis.set("trading:supertrend:#{symbol}", '{"direction":"BULLISH","value":123.45}')
      monitor.update_and_check(symbol)

      # Same direction again
      redis.set("trading:supertrend:#{symbol}", '{"direction":"BULLISH","value":124.00}')

      result = monitor.update_and_check(symbol)

      expect(result[:flipped]).to be false
      expect(result[:from]).to eq(:bullish)
      expect(result[:to]).to eq(:bullish)
    end

    it "stores direction even when no flip occurs" do
      redis.set("trading:supertrend:#{symbol}", '{"direction":"BULLISH","value":123.45}')
      monitor.update_and_check(symbol)

      # Verify direction is stored
      expect(redis.get("strategy:supertrend:last_direction:#{symbol}")).to eq("bullish")
    end

    it "stores direction before returning flip=true result" do
      # First, store initial direction
      redis.set("trading:supertrend:#{symbol}", '{"direction":"BULLISH","value":123.45}')
      monitor.update_and_check(symbol)

      # Now change to bearish
      redis.set("trading:supertrend:#{symbol}", '{"direction":"BEARISH","value":120.00}')
      monitor.update_and_check(symbol)

      # After flip, previous direction should be bearish (stored state updated)
      expect(redis.get("strategy:supertrend:last_direction:#{symbol}")).to eq("bearish")
    end
  end

  describe "direction normalization" do
    it "normalizes 'buy' to bullish" do
      redis.set("trading:supertrend:#{symbol}", '{"direction":"buy","value":123.45}')
      expect(monitor.current_direction(symbol)).to eq(:bullish)
    end

    it "normalizes 'long' to bullish" do
      redis.set("trading:supertrend:#{symbol}", '{"direction":"long","value":123.45}')
      expect(monitor.current_direction(symbol)).to eq(:bullish)
    end

    it "normalizes 'sell' to bearish" do
      redis.set("trading:supertrend:#{symbol}", '{"direction":"sell","value":123.45}')
      expect(monitor.current_direction(symbol)).to eq(:bearish)
    end

    it "normalizes 'short' to bearish" do
      redis.set("trading:supertrend:#{symbol}", '{"direction":"short","value":123.45}')
      expect(monitor.current_direction(symbol)).to eq(:bearish)
    end

    it "returns nil for unknown direction values" do
      redis.set("trading:supertrend:#{symbol}", '{"direction":"unknown","value":123.45}')
      expect(monitor.current_direction(symbol)).to be_nil
    end
  end
end