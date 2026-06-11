# frozen_string_literal: true

require "rails_helper"

RSpec.describe Portfolio::GrowthScaler do
  let(:scaler) { described_class.new(base_risk_pct: 0.005) }

  it "cuts risk in half on 5% drawdown" do
    pct = scaler.scale_risk(drawdown_pct: 6.0, equity_change_pct: 0.0)
    expect(pct.to_f).to eq(0.0025)
  end

  it "halts trading on 10% drawdown" do
    pct = scaler.scale_risk(drawdown_pct: 11.0, equity_change_pct: 0.0)
    expect(pct.to_f).to eq(0.0)
  end

  it "increases risk by 10% on 20% equity growth" do
    pct = scaler.scale_risk(drawdown_pct: 0.0, equity_change_pct: 25.0)
    expect(pct.to_f).to eq(0.0055)
  end
end
