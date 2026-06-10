# frozen_string_literal: true

require "rails_helper"
require_relative "../../app/ha/leader_election"

RSpec.describe Ha::LeaderElection do
  let(:redis_mock) { double }
  let(:election) { described_class.new(redis: redis_mock) }

  it "acquires lock when redis set is successful" do
    allow(redis_mock).to receive(:set).with("trading_leader_lock", election.node_id, nx: true, ex: 10).and_return(true)
    expect(election.acquire!).to be(true)
  end

  it "fails to acquire lock when redis set is unsuccessful" do
    allow(redis_mock).to receive(:set).with("trading_leader_lock", election.node_id, nx: true, ex: 10).and_return(false)
    expect(election.acquire!).to be(false)
  end
end
