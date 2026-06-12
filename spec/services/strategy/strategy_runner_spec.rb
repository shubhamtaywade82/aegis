# frozen_string_literal: true

require "rails_helper"

RSpec.describe Strategy::StrategyRunner do
  let(:strategy) { instance_double(Strategy::SupertrendStrategy) }

  describe "#start" do
    it "sets running? to true" do
      allow(strategy).to receive(:execute).and_return(nil)
      runner = described_class.new(strategy: strategy, check_interval_seconds: 0.1)
      runner.start
      expect(runner.running?).to be true
      runner.stop
    end

    it "creates a thread that calls strategy.execute" do
      allow(strategy).to receive(:execute).and_return(nil)
      runner = described_class.new(strategy: strategy, check_interval_seconds: 0.1)
      runner.start
      sleep 0.3
      expect(strategy).to have_received(:execute).at_least(:once)
      runner.stop
    end
  end

  describe "#stop" do
    it "sets running? to false and joins the thread" do
      allow(strategy).to receive(:execute).and_return(nil)
      runner = described_class.new(strategy: strategy, check_interval_seconds: 0.1)
      runner.start
      sleep 0.2
      runner.stop
      expect(runner.running?).to be false
      expect(runner.thread).not_to be_alive
    end
  end

  describe "#running?" do
    it "is initially false" do
      runner = described_class.new(strategy: strategy)
      expect(runner.running?).to be false
    end
  end

  describe "idempotency" do
    it "start does not create a second thread" do
      runner = described_class.new(strategy: strategy, check_interval_seconds: 0.1)
      runner.start
      first_thread = runner.thread
      runner.start
      expect(runner.thread).to be(first_thread)
      runner.stop
    end
  end

  describe "stop safety" do
    it "stop is safe when not running" do
      runner = described_class.new(strategy: strategy)
      expect { runner.stop }.not_to raise_error
    end
  end

  describe "error handling" do
    it "catches errors during strategy.execute and continues" do
      call_count = 0
      allow(strategy).to receive(:execute) do
        call_count += 1
        raise StandardError, "boom" if call_count == 1
      end

      runner = described_class.new(strategy: strategy, check_interval_seconds: 0.1)
      runner.start
      sleep 0.3

      expect(call_count).to be > 1
      expect(runner.running?).to be true
      runner.stop
    end
  end

  describe "thread lifecycle" do
    it "thread exits cleanly after stop" do
      allow(strategy).to receive(:execute).and_return(nil)
      runner = described_class.new(strategy: strategy, check_interval_seconds: 0.1)
      runner.start
      runner.stop
      expect(runner.thread).not_to be_alive
    end
  end
end