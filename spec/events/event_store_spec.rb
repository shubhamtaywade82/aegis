# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/events/event"
require_relative "../../app/events/event_store"
require_relative "../../app/events/event_bus"

RSpec.describe Events::EventStore do
  let(:store) { described_class.new }
  let(:bus) { Events::EventBus.new }
  let(:event) { Events::Event.new(type: "OrderFilled", payload: { pnl: 10.0 }, occurred_at: Time.now) }

  it "appends and queries events" do
    store.append(event)
    expect(store.events).to eq([ event ])
    expect(store.query(type: "OrderFilled")).to eq([ event ])
    expect(store.query(type: "Other")).to be_empty
  end

  it "replays events to a bus" do
    store.append(event)
    received = []
    bus.subscribe("OrderFilled") { |e| received << e }
    store.replay(bus)
    expect(received).to eq([ event ])
  end
end
