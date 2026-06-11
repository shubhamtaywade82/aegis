# frozen_string_literal: true

require "rails_helper"

RSpec.describe Monitoring::DashboardService do
  let(:registry) { Monitoring::MetricsRegistry.new }
  let(:portfolio) { Execution::Portfolio.new(cash_balance: 10_000.0, leverage: 5) }
  let(:service) do
    described_class.new(
      metrics_registry: registry,
      portfolio: portfolio,
      system_status: {
        rest_connected: true,
        ws_connected: true,
        in_cooldown: false,
        kill_switch_active: false
      }
    )
  end

  it "renders dashboard layout properly" do
    data = service.render
    expect(data[:strategy][:signals_today]).to eq(0)
    expect(data[:portfolio][:equity]).to eq(10_000.0)
    expect(data[:infrastructure][:rest_status]).to eq("ONLINE")
    expect(data[:risk][:cooldown_status]).to eq("INACTIVE")
  end
end
