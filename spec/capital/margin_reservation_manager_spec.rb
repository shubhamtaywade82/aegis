# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/capital/margin_reservation_manager"

RSpec.describe Capital::MarginReservationManager do
  let(:manager) { described_class.new }

  it "reserves and releases margin for order IDs" do
    manager.reserve!("order_123", 300.0)
    expect(manager.total_reserved.to_f).to eq(300.0)

    released = manager.release!("order_123")
    expect(released.to_f).to eq(300.0)
    expect(manager.total_reserved.to_f).to eq(0.0)
  end
end
