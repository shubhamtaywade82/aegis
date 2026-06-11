# frozen_string_literal: true

require "rails_helper"

RSpec.describe Monitoring::AlertEngine do
  let(:notifier) { Notifiers::TelegramNotifier.new }
  let(:engine) { described_class.new(notifier: notifier) }
  let(:registry) { Monitoring::MetricsRegistry.new }

  it "does not trigger alerts when metrics are normal" do
    engine.check_metrics!(registry)
    expect(engine.alerts).to be_empty
  end

  it "triggers warning when daily loss usage is above 80%" do
    registry.record(:daily_loss_usage, 0.82)
    engine.check_metrics!(registry)
    expect(engine.alerts.first[:severity]).to eq(:warning)
    expect(engine.alerts.first[:message]).to include("Daily loss usage warning")
    expect(notifier.sent_messages.first).to include("Daily loss usage warning")
  end

  it "triggers emergency when daily loss limit is breached" do
    registry.record(:daily_loss_usage, 1.0)
    engine.check_metrics!(registry)
    expect(engine.alerts.first[:severity]).to eq(:emergency)
    expect(engine.alerts.first[:message]).to include("Daily loss limit breached")
  end

  it "triggers critical alert on websocket outage" do
    registry.record(:websocket_reconnects_outage_seconds, 35)
    engine.check_metrics!(registry)
    expect(engine.alerts.first[:severity]).to eq(:critical)
  end

  it "triggers critical alert on reconciliation failure" do
    registry.record(:reconciliation_failures, 1)
    engine.check_metrics!(registry)
    expect(engine.alerts.first[:severity]).to eq(:critical)
  end
end
