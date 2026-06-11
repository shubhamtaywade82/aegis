# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::TelegramNotifier do
  let(:notifier) { described_class.new(token: "test", chat_id: "123") }

  it "sends alerts formatted properly" do
    notifier.notify(severity: :emergency, message: "Server on fire")
    expect(notifier.sent_messages.first).to include("🚨 Alert: Server on fire")
  end

  it "sends position open notifications" do
    notifier.notify_position_opened(
      symbol: "SOLUSDT",
      side: :long,
      entry: 185.40,
      sl: 181.20,
      tp: 193.80,
      qty: 0.50,
      risk_pct: 0.48
    )
    expect(notifier.sent_messages.first).to include("🟢 Position Opened")
    expect(notifier.sent_messages.first).to include("SOLUSDT LONG")
    expect(notifier.sent_messages.first).to include("Entry: 185.4")
  end

  it "sends position closed notifications" do
    notifier.notify_position_closed(
      symbol: "SOLUSDT",
      pnl: 48.20,
      equity: 10548
    )
    expect(notifier.sent_messages.first).to include("🔵 Position Closed")
    expect(notifier.sent_messages.first).to include("PnL: +$48.2")
  end

  it "sends risk rejected notifications" do
    notifier.notify_risk_rejected(
      symbol: "SOLUSDT",
      reason: "Exposure exceeded",
      usage_pct: 54,
      limit_pct: 50
    )
    expect(notifier.sent_messages.first).to include("🛑 Trade Rejected")
    expect(notifier.sent_messages.first).to include("Exposure exceeded")
  end

  it "sends kill switch alerts" do
    notifier.notify_kill_switch
    expect(notifier.sent_messages.first).to include("EMERGENCY STOP")
  end
end
