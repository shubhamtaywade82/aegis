# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/ha/health_monitor"

RSpec.describe Ha::HealthMonitor do
  let(:election) { double }
  let(:recon) { double }
  let(:monitor) { described_class.new(leader_election: election, reconciliation_service: recon) }

  it "passes liveness check always" do
    expect(monitor.liveness_check).to be(true)
  end

  it "fails readiness if leader has a reconciliation mismatch" do
    allow(election).to receive(:active?).and_return(true)
    allow(recon).to receive(:reconcile!).and_return(false)

    expect(monitor.readiness_check).to be(false)
  end
end
