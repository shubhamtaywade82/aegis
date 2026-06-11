# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ha::FailoverCoordinator do
  let(:election) { double }
  let(:recon) { double }
  let(:engine) { double }
  let(:coordinator) do
    described_class.new(
      leader_election: election,
      reconciliation_service: recon,
      execution_engine: engine
    )
  end

  it "starts in standby mode" do
    expect(coordinator.status).to eq(:standby)
  end

  it "transitions to active if leadership acquired and reconciled successfully" do
    allow(election).to receive(:acquire!).and_return(true)
    allow(recon).to receive(:reconcile!).and_return(true)

    expect(coordinator.run_cycle!).to eq(:active)
  end

  it "transitions to paused_mismatch if leadership acquired but reconciliation fails" do
    allow(election).to receive(:acquire!).and_return(true)
    allow(recon).to receive(:reconcile!).and_return(false)

    expect(coordinator.run_cycle!).to eq(:paused_mismatch)
  end
end
