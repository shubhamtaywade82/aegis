# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/monitoring/metrics_registry"
require_relative "../../app/events/event"
require_relative "../../app/events/event_bus"

RSpec.describe Monitoring::MetricsRegistry do
  let(:registry) { described_class.new }
  let(:bus) { Events::EventBus.new }

  it "tracks and records individual metrics" do
    registry.record(:latency_ms, 120)
    expect(registry.get(:latency_ms)).to eq(120)
    expect(registry.history_for(:latency_ms).first[:value]).to eq(120)
  end

  it "increments counters" do
    registry.increment(:signals_generated)
    registry.increment(:signals_generated, 2)
    expect(registry.get(:signals_generated)).to eq(3)
  end

  it "processes events through event bus binding" do
    registry.bind_to_event_bus(bus)
    bus.publish(Events::Event.new(type: "SignalGenerated"))
    expect(registry.get(:signals_generated)).to eq(1)
  end

  it "calculates derived trading stats" do
    registry.record(:wins, 2)
    registry.record(:losses, 1)
    registry.record(:gross_profit, 25.0)
    registry.record(:gross_loss, 10.0)
    registry.record(:orders_submitted, 5)
    registry.record(:orders_filled, 3)

    expect(registry.win_rate).to eq(0.6667)
    expect(registry.profit_factor).to eq(2.5)
    expect(registry.fill_ratio).to eq(0.6)
  end
end
