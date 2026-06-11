# frozen_string_literal: true

require "rails_helper"

RSpec.describe TradingChannel do
  let(:mock_connection) { double("Connection", identifiers: {}) }
  let(:mock_identifiers) { {}.to_json }

  describe "#subscribed" do
    it "streams from the correct trading channel for the symbol" do
      channel = described_class.new(mock_connection, mock_identifiers)
      allow(channel).to receive(:stream_from)
      allow(channel).to receive(:params).and_return({ symbol: "BTCUSDT" })

      channel.subscribed

      expect(channel).to have_received(:stream_from).with("trading:BTCUSDT")
    end

    it "handles different symbols correctly" do
      channel = described_class.new(mock_connection, mock_identifiers)
      allow(channel).to receive(:stream_from)
      allow(channel).to receive(:params).and_return({ symbol: "ETHUSDT" })

      channel.subscribed

      expect(channel).to have_received(:stream_from).with("trading:ETHUSDT")
    end
  end

  describe "#unsubscribed" do
    it "cleans up gracefully" do
      channel = described_class.new(mock_connection, mock_identifiers)

      # Should not raise any errors
      expect { channel.unsubscribed }.not_to raise_error
    end
  end
end