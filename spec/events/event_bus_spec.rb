# frozen_string_literal: true

require "rails_helper"

RSpec.describe Events::EventBus do
  let(:bus) { described_class.new }
  let(:event) { Events::Event.new(type: "OrderFilled", payload: { pnl: 10.0 }) }

  it "subscribes and publishes events to specific listeners" do
    received = []
    bus.subscribe("OrderFilled") { |e| received << e }
    bus.publish(event)
    expect(received).to eq([ event ])
  end

  it "subscribes and publishes events to global listeners" do
    received = []
    bus.subscribe_all { |e| received << e }
    bus.publish(event)
    expect(received).to eq([ event ])
  end
end
