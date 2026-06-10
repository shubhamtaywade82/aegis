# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/soak/soak_coordinator"

RSpec.describe Soak::SoakCoordinator do
  let(:coordinator) { described_class.new }

  before do
    coordinator.start_session!
  end

  it "starts and stops a soak session" do
    expect(coordinator.status).to eq(:running)
    coordinator.stop_session!
    expect(coordinator.status).to eq(:stopped)
  end

  it "certifies a perfect soak run" do
    coordinator.verify_order_integrity(submitted: 10, filled: 8, cancelled: 1, rejected: 1)
    coordinator.verify_position_reconciliation({}, {})
    coordinator.verify_event_integrity(generated: 100, persisted: 100)
    coordinator.track_infrastructure_health(memory_mb: 200.0, cpu_percent: 15.0)

    coordinator.stop_session!
    report = coordinator.generate_report

    expect(report).to be_certified
    expect(report.uptime_percentage).to eq(100.0)
    expect(report.orders_processed).to eq(10)
  end

  it "fails certification if uptime is below 99%" do
    coordinator.record_ws_outage(seconds: 1000.0)
    coordinator.instance_variable_set(:@start_time, Time.now - 1000.0)

    coordinator.stop_session!
    report = coordinator.generate_report

    expect(report).not_to be_certified
    expect(report.uptime_percentage).to be < 99.0
  end

  it "fails certification on reconciliation mismatch" do
    coordinator.verify_position_reconciliation({ "SOLUSDT" => 10.0 }, {})
    coordinator.stop_session!
    report = coordinator.generate_report

    expect(report).not_to be_certified
    expect(report.reconciliation_failures).to eq(1)
  end
end
