# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/live/divergence_monitor"

RSpec.describe Live::DivergenceMonitor do
  let(:monitor) { described_class.new }

  it "measures slippage correctly" do
    monitor.record_fill(expected_price: 100.0, actual_price: 101.0)
    expect(monitor.average_slippage).to eq(0.01)
  end

  it "measures pnl drift correctly" do
    monitor.record_pnl(expected_pnl: 100.0, actual_pnl: 95.0)
    expect(monitor.pnl_drift).to eq(-0.05)
  end
end
